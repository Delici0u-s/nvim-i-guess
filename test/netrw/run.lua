-- Headless check of the netrw tree-view file operations (utils/netrw.lua):
-- D / d / R act on the entry under the cursor, not on the folder expanded
-- last, and the tree keeps its expanded folders and sort order afterwards.
--
--   nvim --headless -c "luafile test/netrw/run.lua"
--
-- Works in a fresh temp folder only. Exits non-zero on any failure.

local failures = 0

local function check(ok, what, detail)
	print(("%s  %s%s"):format(ok and "PASS" or "FAIL", what, (not ok and detail) and ("  -- " .. detail) or ""))
	if not ok then
		failures = failures + 1
	end
	return ok
end

local ops = require("utils.netrw")

-- Prompts answered by the test.
local answer = {}
vim.fn.confirm = function()
	return answer.confirm or 2
end
vim.ui.input = function(_, cb)
	cb(answer.input)
end

local root = vim.fn.tempname()
local function mk(rel, file)
	local p = vim.fs.joinpath(root, rel)
	if file then
		vim.fn.mkdir(vim.fs.dirname(p), "p")
		vim.fn.writefile({}, p)
	else
		vim.fn.mkdir(p, "p")
	end
end
mk("bla/inner")
mk("bla/f.txt", true)
mk("bla/a.txt", true)
mk("zzz/inner") -- same name as bla/inner: the wrong-target trap
mk("zzz/z.txt", true)
for i = 1, 30 do -- many entries, long names
	mk(("many/%02d_%s.txt"):format(i, ("x"):rep(i * 3)), true)
end
mk("many/sub")

local function lines()
	return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end
local function show()
	return table.concat(lines(), " | ")
end
local function goto_entry(pat)
	vim.api.nvim_win_set_cursor(0, { 1, 0 })
	return vim.fn.search(pat, "cW") > 0
end
local function expand(pat)
	assert(goto_entry(pat), "no line " .. pat)
	vim.cmd.normal(vim.keycode("<Plug>NetrwLocalBrowseCheck"))
end
local function line_of(text)
	for i, l in ipairs(lines()) do
		if l == text then
			return i
		end
	end
end
local function before(a, b)
	local la, lb = line_of(a), line_of(b)
	return la and lb and la < lb
end
local function exists(rel)
	return vim.uv.fs_lstat(vim.fs.joinpath(root, rel)) ~= nil
end

vim.g.netrw_liststyle = ops.TREE
vim.cmd.Explore(vim.fn.fnameescape(root))
check(vim.bo.filetype == "netrw", "netrw opened", show())

expand([[^| bla/$]])
expand([[^| zzz/$]]) -- now b:netrw_curdir is zzz/
check(before("| | inner/", "| | a.txt"), "fresh expand lists folders first", show())

-- D on bla/inner must delete bla/inner, not zzz/inner.
goto_entry([[^| | inner/$]])
check(ops.entry() and ops.entry().path == vim.fs.joinpath(root, "bla/inner"), "entry() resolves bla/inner")
answer.confirm = 2
ops.delete()
check(exists("bla/inner"), "declined confirm keeps folder")
answer.confirm = 1
goto_entry([[^| | inner/$]])
ops.delete()
check(not exists("bla/inner"), "D deleted bla/inner")
check(exists("zzz/inner"), "D left zzz/inner alone")
check(line_of("| zzz/") and line_of("| | z.txt"), "zzz/ still expanded after delete", show())

-- d on a file inside bla/ creates next to it, and order stays netrw's.
goto_entry([[^| | f.txt$]])
answer.input = "newdir"
ops.mkdir()
check(exists("bla/newdir"), "d created bla/newdir")
check(not exists("zzz/newdir"), "d did not create in zzz/")
check(before("| | newdir/", "| | a.txt"), "after refresh folders still sort first", show())
check(vim.fn.getline(".") == "| | newdir/", "cursor on the new folder", vim.fn.getline("."))

-- d on a collapsed folder creates inside it and opens it.
goto_entry([[^| many/$]])
answer.input = "made"
ops.mkdir()
check(exists("many/made"), "d on folder creates inside it")
check(before("| | made/", "| | 01_xxx.txt"), "collapsed folder got expanded and sorted", show())

-- R on a nested file.
goto_entry([[^| | a.txt$]])
answer.input = "renamed.txt"
ops.rename()
check(exists("bla/renamed.txt") and not exists("bla/a.txt"), "R renamed bla/a.txt relative to its folder")
check(vim.fn.getline(".") == "| | renamed.txt", "cursor follows renamed file", vim.fn.getline("."))
goto_entry([[^| | renamed.txt$]])
answer.input = "f.txt"
ops.rename()
check(exists("bla/renamed.txt"), "R refuses to overwrite an existing file")

-- Nested folder inside a collapsed parent stays hidden but remembered.
expand([[^| | newdir/$]])
goto_entry([[^| | newdir/$]])
answer.input = "deep"
ops.mkdir()
check(line_of("| | | deep/"), "nested expansion survives refresh", show())

-- Root and ../ are refused.
goto_entry([[^\.\./$]])
check(ops.entry() == nil, "../ is not an entry")

vim.fn.delete(root, "rf")
print(failures == 0 and "ALL PASS" or (failures .. " FAILURE(S)"))
vim.cmd(failures == 0 and "qa!" or "cq!")
