-- netrw file operations that work in tree view.
--
-- Logic only -- configs/core/netrw.lua binds the keys. Two netrw bugs
-- (runtime netrw, nvim 0.11) are worked around here:
--
--  1. Stale target path. netrw's D (delete), d (mkdir), % (new file) and
--     R (rename) build the path from b:netrw_curdir / the tree root, not
--     from the line under the cursor. In tree view b:netrw_curdir is the
--     folder expanded *last*, so after expanding zzz/, D on bla/inner/
--     targets zzz/inner -- "unable to delete directory", or the wrong
--     folder if one of that name exists there.
--  2. Lost ordering. netrw's refresh re-lists every expanded folder with a
--     plain sort(), ignoring g:netrw_sort_sequence (folders first, ...),
--     so after any change the tree's order differs from a fresh expand.
--
-- Paths are resolved through netrw's own helpers (netrw#Call to
-- NetrwGetWord / NetrwTreePath), and the refresh re-expands folders through
-- <Plug>NetrwLocalBrowseCheck, so netrw itself still does all listing and
-- sorting. Marked files and remote (scp://) buffers fall back to netrw.

local M = {}

-- netrw's documented g:netrw_liststyle value for the tree view.
M.TREE = 3

local function call(fn, ...)
	return vim.fn["netrw#Call"](fn, ...)
end

local function strip(path)
	return (path:gsub("/+$", ""))
end

local function plug(name)
	vim.cmd.normal(vim.keycode("<Plug>" .. name))
end

local function warn(msg, level)
	vim.notify("netrw: " .. msg, level or vim.log.levels.WARN)
end

local function is_tree()
	return vim.w.netrw_liststyle == M.TREE
end

--- True in a local netrw buffer with no marked files: the case handled here.
function M.handles_current()
	if vim.bo.filetype ~= "netrw" then
		return false
	end
	local dir = vim.b.netrw_curdir or vim.api.nvim_buf_get_name(0)
	if vim.fn["netrw#CheckIfRemote"](dir) == 1 then
		return false
	end
	local marks = vim.fn["netrw#Expose"]("netrwmarkfilelist_" .. vim.api.nvim_get_current_buf())
	return type(marks) ~= "table" or #marks == 0
end

--- The entry under the cursor.
---@return { path: string, is_dir: boolean, is_link: boolean, is_root: boolean }|nil
---  nil on "../", "./" and banner lines.
function M.entry()
	if vim.w.netrw_bannercnt and vim.fn.line(".") < vim.w.netrw_bannercnt then
		return nil
	end
	local word = call("NetrwGetWord")
	if word == "" or word == "../" or word == "./" then
		return nil
	end

	local path
	if is_tree() then
		local top = strip(vim.w.netrw_treetop)
		local tp = call("NetrwTreePath", vim.w.netrw_treetop)
		if word:sub(-1) == "/" or tp:sub(-1) ~= "/" then
			path = tp -- a folder or a symlink: the tree path is the entry itself
		else
			path = tp .. word -- a file: the tree path is its folder
		end
		if strip(path) == top then
			return { path = top, is_dir = true, is_link = false, is_root = true }
		end
	else
		path = vim.fs.joinpath(vim.b.netrw_curdir, word)
	end

	path = strip(path)
	local stat = vim.uv.fs_lstat(path)
	local is_link = stat ~= nil and stat.type == "link"
	return {
		path = path,
		is_dir = vim.fn.isdirectory(path) == 1,
		is_link = is_link,
		is_root = false,
	}
end

--- Folder that d / % create in: the folder under the cursor, else the
--- folder holding the entry under the cursor.
function M.target_dir()
	local e = M.entry()
	if not e or e.is_root then
		return strip(is_tree() and vim.w.netrw_treetop or vim.b.netrw_curdir)
	end
	if e.is_dir and not e.is_link and is_tree() then
		return e.path
	end
	return vim.fs.dirname(e.path)
end

--- Line showing `path` (nil when it isn't visible). Folder lines only
--- when `dirs_only`, which skips most lines.
local function find_line(path, dirs_only)
	path = strip(path)
	local first = math.max(vim.w.netrw_bannercnt or 1, 1)
	for l = first, vim.fn.line("$") do
		if not dirs_only or vim.fn.getline(l):match("/$") then
			vim.api.nvim_win_set_cursor(0, { l, 0 })
			local e = M.entry()
			if e and e.path == path then
				return l
			end
		end
	end
end

--- Folders currently shown expanded: those netrw holds a listing for whose
--- every ancestor up to the root is expanded too. (netrw keeps the listing
--- of a folder inside a collapsed one, but doesn't show it.)
local function open_dirs(dict, top)
	local held = {}
	for key in pairs(dict) do
		held[strip(key)] = true
	end
	local open = {}
	for dir in pairs(held) do
		local p, shown = dir, dir ~= top
		while shown and p ~= top do
			p = vim.fs.dirname(p)
			shown = held[p] == true and #p >= #top
		end
		if shown then
			open[#open + 1] = dir
		end
	end
	return open
end

--- Redraw the netrw buffer, keeping the tree's expanded folders and
--- netrw's sort order, and put the cursor on `opts.focus` (a path) if shown.
---@param opts? { focus?: string, expand?: string[] } expand: folders to open too
function M.refresh(opts)
	if vim.bo.filetype ~= "netrw" then
		return
	end
	opts = opts or {}
	local cur = M.entry()
	local focus = opts.focus or (cur and cur.path)
	local view = vim.fn.winsaveview()

	local reopen = {}
	if is_tree() and vim.w.netrw_treedict then
		local top = strip(vim.w.netrw_treetop)
		local dict = vim.w.netrw_treedict
		reopen = open_dirs(dict, top)
		vim.list_extend(reopen, opts.expand or {})
		-- Drop every sub-listing so the refresh lists only the root; each
		-- folder is then re-expanded the normal way, which sorts properly.
		local root = {}
		for key, list in pairs(dict) do
			if strip(key) == top then
				root[key] = list
			end
		end
		vim.w.netrw_treedict = root
	end

	plug("NetrwRefresh")

	if is_tree() and #reopen > 0 then
		local seen = {}
		local _, top_depth = strip(vim.w.netrw_treetop):gsub("/", "")
		table.sort(reopen, function(a, b)
			local _, da = a:gsub("/", "")
			local _, db = b:gsub("/", "")
			return da == db and a < b or da < db
		end)
		for _, dir in ipairs(reopen) do
			local _, depth = dir:gsub("/", "")
			if not seen[dir] and depth > top_depth and find_line(dir, true) then
				seen[dir] = true
				plug("NetrwLocalBrowseCheck")
			end
		end
	end

	vim.fn.winrestview(view)
	if focus then
		local line = find_line(focus, false)
		if line then
			vim.api.nvim_win_set_cursor(0, { line, 0 })
		else
			vim.fn.winrestview(view)
		end
	end
end

--- Delete the entry under the cursor (folders recursively), after a
--- confirm that defaults to No.
function M.delete()
	local e = M.entry()
	if not e or e.is_root then
		return warn("nothing to delete on this line")
	end
	local kind = e.is_link and "symlink" or e.is_dir and "folder (recursively)" or "file"
	if vim.fn.confirm(("Delete %s %s?"):format(kind, e.path), "&Yes\n&No", 2) ~= 1 then
		return
	end
	-- A symlink is removed itself, never what it points to.
	local flags = (e.is_dir and not e.is_link) and "rf" or ""
	if vim.fn.delete(e.path, flags) ~= 0 then
		return warn("could not delete " .. e.path, vim.log.levels.ERROR)
	end
	M.refresh()
end

--- Ask for a name and create a folder (nested "a/b" allowed) in target_dir().
function M.mkdir()
	local dir = M.target_dir()
	vim.ui.input({ prompt = "New folder in " .. dir .. "/: ", completion = "dir" }, function(name)
		if not name or name == "" then
			return
		end
		local path = vim.fs.joinpath(dir, name)
		if vim.uv.fs_lstat(path) then
			return warn(path .. " already exists")
		end
		if vim.fn.mkdir(path, "p") == 0 then
			return warn("could not create " .. path, vim.log.levels.ERROR)
		end
		local first = name:match("^/*([^/]+)")
		M.refresh({ focus = vim.fs.joinpath(dir, first), expand = { dir } })
	end)
end

--- Ask for a name and edit that new file in target_dir() (written on :w,
--- like netrw's own %).
function M.new_file()
	local dir = M.target_dir()
	vim.ui.input({ prompt = "New file in " .. dir .. "/: ", completion = "file" }, function(name)
		if not name or name == "" then
			return
		end
		local path = vim.fs.joinpath(dir, name)
		vim.fn.mkdir(vim.fs.dirname(path), "p")
		vim.cmd.edit(vim.fn.fnameescape(path))
	end)
end

--- Rename / move the entry under the cursor. Relative names are taken
--- from the entry's folder. Refuses to overwrite an existing path.
function M.rename()
	local e = M.entry()
	if not e or e.is_root then
		return warn("nothing to rename on this line")
	end
	vim.ui.input({ prompt = "Rename to: ", default = e.path, completion = "file" }, function(new)
		if not new or new == "" then
			return
		end
		new = vim.fs.normalize(new)
		if new:sub(1, 1) ~= "/" then
			new = vim.fs.joinpath(vim.fs.dirname(e.path), new)
		end
		new = strip(new)
		if new == e.path then
			return
		end
		if vim.uv.fs_lstat(new) then
			return warn(new .. " already exists; not overwriting")
		end
		vim.fn.mkdir(vim.fs.dirname(new), "p")
		local ok, err = vim.uv.fs_rename(e.path, new)
		if not ok then
			return warn("could not rename: " .. tostring(err), vim.log.levels.ERROR)
		end
		M.refresh({ focus = new })
	end)
end

return M
