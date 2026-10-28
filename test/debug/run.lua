-- Headless debugger check. Runs with the full config:
--
--   test/debug/build.sh
--   nvim --headless -c "luafile test/debug/run.lua"
--
-- Optional environment:
--   DAP_TEST_UI=dap-view    test another UI than the one in settings.lua
--   DAP_TEST_ONLY=python    run one language only
--
-- Checks that the DAP config loads, every debugger key is mapped with a
-- description, and, for each test program that exists, that a real session
-- stops on the line marked BREAK and shuts down cleanly. Exits non-zero on
-- any failure.

local here = vim.fs.dirname(vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p"))
local failures = 0

local function check(ok, what, detail)
	print(("%s  %s%s"):format(ok and "PASS" or "FAIL", what, (not ok and detail) and ("  -- " .. detail) or ""))
	if not ok then
		failures = failures + 1
	end
	return ok
end

-- 1. Config loads -----------------------------------------------------------
local settings = require("plugins.configs.tools.dap.settings")
settings.ui = os.getenv("DAP_TEST_UI") or settings.ui
print("UI: " .. settings.ui)
local errors = {}
local notify = vim.notify
vim.notify = function(msg, level, ...)
	if level == vim.log.levels.ERROR then
		errors[#errors + 1] = msg
	end
	return notify(msg, level, ...)
end
require("lazy").load({ plugins = { "nvim-dap" } })
check(#errors == 0, "nvim-dap config runs without errors", table.concat(errors, " | "))

local dap = require("dap")
for _, name in ipairs(settings.adapters) do
	check(dap.adapters[name] ~= nil, "adapter registered: " .. name)
end

-- 2. Keys ---------------------------------------------------------------------
for _, key in ipairs(require("plugins.configs.tools.dap.keymaps")) do
	for _, mode in ipairs(type(key.mode) == "table" and key.mode or { key.mode or "n" }) do
		local map = vim.fn.maparg(key[1], mode, false, true)
		check(map.desc ~= nil and map.desc ~= "", ("key %s (%s) mapped with desc"):format(key[1], mode))
	end
end

-- 3. Sessions -----------------------------------------------------------------
local build = vim.fs.joinpath(here, "build")
local programs = {
	{ ft = "c", source = "c/main.c", program = vim.fs.joinpath(build, "c_demo") },
	{ ft = "zig", source = "zig/main.zig", program = vim.fs.joinpath(build, "zig_demo") },
	{ ft = "rust", source = "rust/main.rs", program = vim.fs.joinpath(build, "rust_demo") },
	-- argv: expression evaluated at the breakpoint to prove the arguments arrived.
	{ ft = "python", source = "python/main.py", argv = "sys.argv[1:]", expect = "['one', 'two words']" },
}

local found = require("plugins.configs.tools.dap.launch").executables(build)
check(#found > 0, "program picker lists executables in test/debug/build", "run test/debug/build.sh first")

-- Program picker paths, with vim.ui stubbed. Each select answers with the
-- entry whose label equals the next label in `labels`; prompts are recorded.
do
	local launch = require("plugins.configs.tools.dap.launch")
	local select, input, cwd = vim.ui.select, vim.ui.input, vim.fn.getcwd()
	local typed = vim.fs.joinpath(build, "c_demo")
	local prompts
	local function run(labels)
		prompts = {}
		local step = 0
		vim.ui.select = function(items, opts, cb)
			prompts[#prompts + 1] = opts.prompt
			step = step + 1
			local want = labels[step]
			cb(want and vim.iter(items):find(function(i)
				return opts.format_item(i) == want
			end))
		end
		vim.ui.input = function(_, cb)
			cb(typed)
		end
		local result, done
		coroutine.wrap(function()
			result = launch.pick_program()
			done = true
		end)()
		vim.wait(2000, function()
			return done
		end, 10)
		return result
	end

	vim.cmd.cd(build)
	local first_label = vim.fs.relpath(build, found[1]) .. "*"
	local first = run({ first_label })
	check(first == found[1], "picker: choosing a listed program returns it", tostring(first))

	local via_typing = run({ "Type a path…" })
	check(via_typing == typed, 'picker: "Type a path…" asks for one', tostring(via_typing))

	-- Browse starts where the last pick was (build/), goes up and back down.
	local via_browse = run({ "Browse…", "../", "build/", "rust_demo*" })
	check(
		via_browse == vim.fs.joinpath(build, "rust_demo"),
		'picker: "Browse…" navigates up and into directories',
		tostring(via_browse) .. " prompts: " .. table.concat(prompts, " | ")
	)

	-- No executables under the cwd: the browser opens directly.
	vim.cmd.cd(vim.fs.joinpath(here, "python"))
	local empty = run({ "c_demo*" })
	check(
		empty == typed and prompts[1]:find("^Browse") ~= nil,
		"picker: no executables -> opens the browser",
		tostring(empty) .. " prompts: " .. table.concat(prompts, " | ")
	)

	local cancelled = run({})
	check(cancelled == require("dap").ABORT, "picker: cancelling aborts the launch")
	vim.cmd.cd(cwd)
	vim.ui.select, vim.ui.input = select, input
end

local stopped_line, stopped_frame, ended
dap.listeners.after.event_stopped.test = function(session, body)
	session:request("stackTrace", { threadId = body.threadId, levels = 1 }, function(_, res)
		local frame = res and res.stackFrames[1]
		stopped_frame = frame and frame.id
		stopped_line = frame and frame.line or -1
	end)
end
dap.listeners.after.event_terminated.test = function()
	ended = true
end
dap.listeners.after.disconnect.test = function()
	ended = true
end

local timeout = tonumber(os.getenv("DAP_TEST_TIMEOUT_MS")) or 20000

local only = os.getenv("DAP_TEST_ONLY") -- e.g. DAP_TEST_ONLY=python

for _, p in ipairs(programs) do
	if only and p.ft ~= only then
		goto continue
	end
	local source = vim.fs.joinpath(here, p.source)
	if p.program and vim.fn.executable(p.program) == 0 then
		print(("SKIP  %s: %s not built"):format(p.ft, p.program))
	else
		-- Start from a plain editing window; UI panels may still be focused.
		for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
			if not vim.wo[win].winfixbuf and vim.bo[vim.api.nvim_win_get_buf(win)].buftype == "" then
				vim.api.nvim_set_current_win(win)
				break
			end
		end
		vim.cmd.edit(source)
		local buf = vim.api.nvim_get_current_buf()
		local line
		for i, text in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
			if text:find("BREAK") then
				line = i
				break
			end
		end
		dap.clear_breakpoints()
		vim.api.nvim_win_set_cursor(0, { line, 0 })
		dap.toggle_breakpoint()

		-- The "(args)" configuration, with the arguments prompt answered by a stub,
		-- so the real ask_args path runs.
		local config = vim.iter(dap.configurations[p.ft] or {}):find(function(c)
			return c.request == "launch" and type(c.args) == "function"
		end)
		if check(config ~= nil, p.ft .. ": has a launch configuration that asks for arguments") then
			config = vim.deepcopy(config)
			config.program = p.program or source
			config.cwd = here
			config.console = nil -- no terminal in headless
			local input = vim.ui.input
			vim.ui.input = function(_, cb)
				cb([[one "two words"]])
			end
			stopped_line, stopped_frame, ended = nil, nil, false
			dap.run(config)
			vim.wait(timeout, function()
				return stopped_line ~= nil
			end, 50)
			check(
				stopped_line == line,
				p.ft .. ": stops at BREAK line " .. line,
				"stopped at " .. tostring(stopped_line)
			)
			vim.ui.input = input
			if p.argv and stopped_frame then
				local value
				dap.session():request(
					"evaluate",
					{ expression = p.argv, frameId = stopped_frame, context = "repl" },
					function(_, res)
						value = res and res.result or "error"
					end
				)
				vim.wait(timeout, function()
					return value ~= nil
				end, 50)
				check(value == p.expect, p.ft .. ": program received the arguments", tostring(value))
			end
			local ui = require("plugins.configs.tools.dap.ui")
			for _, action in ipairs({ "scopes", "frames", "eval", "toggle", "toggle" }) do
				-- Actions may have moved focus into a UI window (some forbid
				-- switching buffers), so go back to the source window.
				local win = vim.fn.bufwinid(buf)
				if win ~= -1 then
					vim.api.nvim_set_current_win(win)
				end
				local ok, err = pcall(ui[action])
				check(ok, ("%s: ui.%s() while stopped"):format(p.ft, action), tostring(err))
			end
			local ok, err = pcall(ui.watch, "1 + 1")
			check(ok, p.ft .. ": ui.watch() while stopped", tostring(err))
			dap.terminate()
			vim.wait(timeout, function()
				return ended and dap.session() == nil
			end, 50)
			check(dap.session() == nil, p.ft .. ": session ends on terminate")
		end
	end
	::continue::
end

print(failures == 0 and "\nall checks passed" or ("\n%d check(s) failed"):format(failures))
vim.cmd(failures == 0 and "qa!" or "cq!")
