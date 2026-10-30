-- Toggleable split terminals.
--
-- Logic only -- the keymaps that drive this live in
-- configs/keymaps/terminal.lua. Split so the state machine can be tested and
-- reused without also binding keys.

local M = {}

local function get_buf_dir()
	local path = vim.api.nvim_buf_get_name(0)
	if path == "" then
		return vim.fn.getcwd()
	end
	return vim.fn.fnamemodify(path, ":p:h")
end

local terminals = {
	vertical = { buf = nil, win = nil },
	horizontal = { buf = nil, win = nil },
}

--- Open a split in the current tab showing the terminal, starting it if it
--- isn't running.
local function open(direction, term)
	local dir = get_buf_dir() -- capture before switching windows

	vim.cmd(direction == "vertical" and "vsplit" or "split")
	term.win = vim.api.nvim_get_current_win()

	if not term.buf or not vim.api.nvim_buf_is_valid(term.buf) then
		vim.cmd("lcd " .. vim.fn.fnameescape(dir))
		vim.cmd("terminal")
		term.buf = vim.api.nvim_get_current_buf()
		-- <A-e> (utils/jump.lua) re-shows it this way when it's hidden.
		require("utils.jump").register(term.buf, function()
			M.show(direction)
		end)
	else
		vim.api.nvim_win_set_buf(term.win, term.buf)
	end

	vim.cmd("startinsert")
end

local function get(direction)
	local term = terminals[direction]
	if not term then
		vim.notify("terminal: unknown direction " .. tostring(direction), vim.log.levels.ERROR)
	end
	return term
end

--- Toggle a terminal split. Reuses the buffer across toggles so scrollback and
--- the running shell survive being hidden.
---@param direction "vertical"|"horizontal"
function M.toggle(direction)
	local term = get(direction)
	if not term then
		return
	end

	if term.win and vim.api.nvim_win_is_valid(term.win) then
		vim.api.nvim_win_close(term.win, true)
		term.win = nil
		return
	end

	open(direction, term)
end

--- Show and focus a terminal split: its window in this tab, or a new split.
---@param direction "vertical"|"horizontal"
function M.show(direction)
	local term = get(direction)
	if not term then
		return
	end
	local win = term.win
	if
		win
		and vim.api.nvim_win_is_valid(win)
		and vim.api.nvim_win_get_tabpage(win) == vim.api.nvim_get_current_tabpage()
	then
		vim.api.nvim_set_current_win(win)
		return vim.cmd("startinsert")
	end
	open(direction, term)
end

return M
