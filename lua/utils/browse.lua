-- Netrw-like browser in a vim.ui.select picker: pick a folder to enter it
-- ("../" goes up), pick a file to choose it -- or, when choosing a folder,
-- "✓ Use this folder".
--
-- Used by the debugger's program picker (tools/dap/launch.lua, files =
-- executables) and the runner's run-folder picker (utils/runner.lua,
-- folders). Callback style; pass `select` to drive it with another picker
-- (dap's coroutine-aware one). Logic only, no keys.

local M = {}

-- Entry kinds: label suffix (the `ls -F` convention, so the kind shows even
-- without colour) and the highlight group used where vim.ui.select supports
-- highlighted chunks (snacks does).
M.kinds = {
	dir = { suffix = "/", hl = "Directory" },
	file = { suffix = "", hl = "Normal" },
	action = { suffix = "", hl = "Special" },
}

--- One folder level: "..", subfolders (hidden ones last), then the files
--- `files(path)` accepts (none without it).
---@param dir string
---@param files? fun(path: string): boolean
---@return { path: string, name: string, kind: string }[]
function M.list(dir, files)
	local dirs, found = {}, {}
	for name, type in vim.fs.dir(dir) do
		local path = vim.fs.joinpath(dir, name)
		if type == "directory" or (type == "link" and vim.fn.isdirectory(path) == 1) then
			dirs[#dirs + 1] = { path = path, name = name, kind = "dir", hidden = name:sub(1, 1) == "." }
		elseif files and files(path) then
			found[#found + 1] = { path = path, name = name, kind = "file" }
		end
	end
	table.sort(dirs, function(a, b)
		if a.hidden ~= b.hidden then
			return b.hidden
		end
		return a.name < b.name
	end)
	table.sort(found, function(a, b)
		return a.name < b.name
	end)
	local entries = {}
	local parent = vim.fs.dirname(dir)
	if parent ~= dir then
		entries[1] = { path = parent, name = "..", kind = "dir" }
	end
	return vim.list_extend(vim.list_extend(entries, dirs), found)
end

--- Label of an entry; highlighted chunks when the picker asks for them.
---@param kinds? table overrides of M.kinds (e.g. file = { suffix = "*" })
function M.format(entry, chunks, kinds)
	local kind = (kinds and kinds[entry.kind]) or M.kinds[entry.kind]
	local label = entry.name .. kind.suffix
	return chunks and { { label, kind.hl } } or label
end

---@class utils.browse.Opts
---@field prompt? string    prefix of each level's prompt (default "Browse")
---@field want? "file"|"dir" what is being chosen (default "file")
---@field files? fun(path: string): boolean files to list (want = "file")
---@field kinds? table      label overrides, see M.format
---@field select? fun(items: table, opts: table, cb: fun(item: table|nil)) default vim.ui.select

--- Browse from `dir`; `on_done(path)` gets the choice, or nil if cancelled.
---@param dir string
---@param opts utils.browse.Opts
---@param on_done fun(path: string|nil)
function M.browse(dir, opts, on_done)
	local select = opts.select or vim.ui.select
	local function level(at)
		local entries = M.list(at, opts.want ~= "dir" and opts.files or nil)
		if opts.want == "dir" then
			table.insert(entries, 1, { path = at, name = "✓ Use this folder", kind = "action" })
		end
		select(entries, {
			prompt = ("%s %s: "):format(opts.prompt or "Browse", vim.fn.fnamemodify(at, ":~")),
			format_item = function(e, chunks)
				return M.format(e, chunks, opts.kinds)
			end,
		}, function(entry)
			if not entry then
				return on_done(nil)
			end
			if entry.kind == "dir" then
				return level(entry.path)
			end
			on_done(entry.path)
		end)
	end
	level(dir)
end

return M
