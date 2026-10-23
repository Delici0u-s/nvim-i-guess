-- Compiler diagnostics for standalone .zig files.
--
-- ZLS only reports semantic errors (e.g. "expected type 'void', found
-- 'error{OutOfMemory}'") through build-on-save, which needs a build.zig. For
-- files outside any build.zig project we run the compiler in check-only mode
-- on load and save and publish its errors through vim.diagnostic.

local ns = vim.api.nvim_create_namespace("zig_check")
local running = {} -- bufnr -> vim.system handle, so a newer save cancels the older run

local function has_build_zig(file)
	return vim.fs.root(file, "build.zig") ~= nil
end

local function has_text(bufnr, pattern)
	for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
		if line:find(pattern) then
			return true
		end
	end
	return false
end

-- "path:line:col: error: msg" -> { [absolute path] = diagnostics }. Notes are
-- appended to the preceding error so the context stays attached to it. Errors
-- can land in imported files, so results are grouped by path.
local function parse(stderr, dir)
	local by_path, last = {}, nil
	for line in stderr:gmatch("[^\n]+") do
		local path, lnum, col, kind, msg = line:match("^(.-):(%d+):(%d+): (%a+): (.*)$")
		if path and (kind == "error" or kind == "note") then
			if kind == "error" then
				local full = vim.fs.normalize(path:sub(1, 1) == "/" and path or vim.fs.joinpath(dir, path))
				last = nil
				if vim.fn.filereadable(full) == 1 then
					last = {
						lnum = tonumber(lnum) - 1,
						col = tonumber(col) - 1,
						severity = vim.diagnostic.severity.ERROR,
						source = "zig",
						message = msg,
					}
					by_path[full] = by_path[full] or {}
					table.insert(by_path[full], last)
				end
			elseif last then
				last.message = last.message .. "\n" .. msg
			end
		end
	end
	return by_path
end

local touched = {} -- bufnr -> buffers it published diagnostics to, cleared on its next run

local function publish(bufnr, by_path)
	for _, b in ipairs(touched[bufnr] or {}) do
		if vim.api.nvim_buf_is_valid(b) then
			vim.diagnostic.reset(ns, b)
		end
	end
	touched[bufnr] = {}
	for path, diags in pairs(by_path) do
		local target = vim.fn.bufadd(path)
		vim.diagnostic.set(ns, target, diags)
		table.insert(touched[bufnr], target)
	end
end

local function check(bufnr)
	local file = vim.fs.normalize(vim.api.nvim_buf_get_name(bufnr))
	if file == "" or vim.fn.executable("zig") == 0 then
		return
	end
	if has_build_zig(file) then
		publish(bufnr, {}) -- ZLS build-on-save owns this file
		return
	end

	local dir = vim.fs.dirname(file)
	local cmd = { "zig", has_text(bufnr, "fn%s+main%s*%(") and "build-exe" or "test", "-fno-emit-bin" }
	if has_text(bufnr, "@cImport") or has_text(bufnr, "std%.c[%.%s]") then
		table.insert(cmd, "-lc") -- else libc use fails with a bogus "libc required" error
	end
	table.insert(cmd, file)

	if running[bufnr] then
		running[bufnr]:kill(15)
	end
	running[bufnr] = vim.system(cmd, { text = true, cwd = dir }, function(res)
		vim.schedule(function()
			running[bufnr] = nil
			if res.signal and res.signal ~= 0 then
				return -- cancelled by a newer run
			end
			if vim.api.nvim_buf_is_valid(bufnr) then
				publish(bufnr, parse(res.stderr or "", dir))
			end
		end)
	end)
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
	group = vim.api.nvim_create_augroup("ZigCheck", { clear = true }),
	pattern = "*.zig",
	callback = function(args)
		check(args.buf)
	end,
})

-- Reported positions go stale as soon as the text changes; drop them until the next check.
vim.api.nvim_create_autocmd("TextChanged", {
	group = "ZigCheck",
	pattern = "*.zig",
	callback = function(args)
		vim.diagnostic.reset(ns, args.buf)
	end,
})
