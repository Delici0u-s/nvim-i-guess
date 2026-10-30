-- Headless check of <A-e> (utils/jump.lua): which window it lands in, with
-- several editor windows, tabs, hidden/closed terminals and floats around.
--
--   nvim --headless -c "luafile test/terminal/run.lua"
--
-- Modes (back in Insert mode, Terminal mode) need a real UI; check those by
-- hand. Exits non-zero on any failure.

local failures = 0

local function check(ok, what, detail)
	print(("%s  %s%s"):format(ok and "PASS" or "FAIL", what, (not ok and detail) and ("  -- " .. detail) or ""))
	if not ok then
		failures = failures + 1
	end
	return ok
end

local jump = require("utils.jump")
local term = require("utils.terminal")

local notes = {}
local notify = vim.notify
vim.notify = function(msg, ...)
	notes[#notes + 1] = tostring(msg)
	return notify(msg, ...)
end

local function name(win)
	win = win or vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_win_get_buf(win)
	return vim.bo[buf].buftype == "terminal" and "terminal" or vim.fs.basename(vim.api.nvim_buf_get_name(buf))
end

local function step()
	jump.toggle()
	vim.cmd.stopinsert() -- headless: modes aren't part of this test
end

local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
local function path(file)
	return vim.fs.joinpath(dir, file)
end

-- No terminal yet: a hint, no change.
vim.cmd.edit(path("a.txt"))
step()
check(name() == "a.txt" and notes[#notes]:find("no terminal yet", 1, true), "no terminal: says so, stays")

-- Two editor windows; the shell opened from the second.
vim.cmd.vsplit(path("b.txt"))
local b_win = vim.api.nvim_get_current_win()
term.toggle("vertical")
vim.cmd.stopinsert()
local term_win = vim.api.nvim_get_current_win()
local shell = vim.api.nvim_get_current_buf()
check(name() == "terminal", "shell opens")
step()
check(vim.api.nvim_get_current_win() == b_win, "terminal -> the window it came from (not the first one)")
step()
check(vim.api.nvim_get_current_win() == term_win, "editor -> the terminal")

-- Back to a.txt, then terminal and back: returns to a.txt now.
vim.cmd.wincmd("t")
step()
step()
check(name() == "a.txt", "remembers the latest editor window")

-- Hidden terminal: shown again, in this tab.
term.toggle("vertical")
check(#vim.fn.win_findbuf(vim.fn.bufnr("term://*")) == 0, "shell hidden")
step()
check(name() == "terminal", "hidden terminal is shown again")
term_win = vim.api.nvim_get_current_win() -- a new window
step()

-- Floats (pickers, notifications) never count as the editor window.
local float = vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), true, {
	relative = "editor",
	row = 1,
	col = 1,
	width = 10,
	height = 2,
})
vim.api.nvim_set_current_win(term_win)
step()
check(name() == "a.txt", "floats are skipped")
vim.api.nvim_win_close(float, true)

-- The editor window you came from was closed: another one in this tab.
step()
vim.api.nvim_win_close(vim.fn.win_getid(vim.fn.bufwinnr(path("a.txt"))), true)
step()
check(name() == "b.txt", "closed editor window -> another one in this tab")

-- Another tab: the terminal isn't shown there, so it opens in this tab.
vim.cmd.tabnew(path("c.txt"))
local c_tab = vim.api.nvim_get_current_tabpage()
step()
check(name() == "terminal" and vim.api.nvim_get_current_tabpage() == c_tab, "other tab: terminal opens here")
step()
check(name() == "c.txt", "and back to this tab's editor window")

-- A tab with only a terminal: back to the last editor window, in its tab.
vim.cmd.tabnew()
vim.cmd.terminal()
vim.cmd.stopinsert()
local plain = vim.api.nvim_get_current_buf()
step()
check(name() == "c.txt", "terminal-only tab -> last editor window in another tab")

-- Several terminals: the one used last. The plain :terminal isn't shown in
-- this tab and has no owner, so it opens in a split here.
step()
check(vim.api.nvim_get_current_buf() == plain, "several terminals: the one used last (plain :terminal)")
vim.cmd.close()
term.show("vertical")
vim.cmd.stopinsert()
step()
step()
check(vim.api.nvim_get_current_buf() == shell, "several terminals: the one used last (shell)")

vim.fn.delete(dir, "rf")
print(("\n%s"):format(failures == 0 and "all passed" or (failures .. " failed")))
vim.cmd(failures == 0 and "qa!" or "cq!")
