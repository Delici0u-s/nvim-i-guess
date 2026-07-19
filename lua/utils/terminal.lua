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

--- Toggle a terminal split. Reuses the buffer across toggles so scrollback and
--- the running shell survive being hidden.
---@param direction "vertical"|"horizontal"
function M.toggle(direction)
	local term = terminals[direction]
	if not term then
		vim.notify("terminal: unknown direction " .. tostring(direction), vim.log.levels.ERROR)
		return
	end

	if term.win and vim.api.nvim_win_is_valid(term.win) then
		vim.api.nvim_win_close(term.win, true)
		term.win = nil
		return
	end

	local dir = get_buf_dir() -- capture before switching windows

	vim.cmd(direction == "vertical" and "vsplit" or "split")
	term.win = vim.api.nvim_get_current_win()

	if not term.buf or not vim.api.nvim_buf_is_valid(term.buf) then
		vim.cmd("lcd " .. vim.fn.fnameescape(dir))
		vim.cmd("terminal")
		term.buf = vim.api.nvim_get_current_buf()
	else
		vim.api.nvim_win_set_buf(term.win, term.buf)
	end

	vim.cmd("startinsert")
end

return M
