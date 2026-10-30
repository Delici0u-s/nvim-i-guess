-- Jump between the editor and terminals with one key (<A-e>, bound in
-- configs/keymaps/terminal.lua).
--
--   From a terminal (shell or Claude): back to the editor window you were in
--   last, in this tab if there is one, else in any tab; in Insert mode if you
--   left it in Insert mode.
--   From an editor window: to the terminal you used last, in Terminal mode.
--   If it's shown in this tab, that window; if it's hidden, its owner shows it
--   (utils/terminal.lua for the <C-n>/<C-h>n shells, the Claude config for
--   Claude); any other terminal opens in a vertical split.
--
-- "Editor window" = any non-floating window not showing a terminal, so
-- pickers and notifications never count, while explorers and diffs do.
--
-- Logic only; testable without the key (test/terminal/run.lua).
local M = {}

local seq = 0
local entered = {} -- editor window -> seq when last entered
local left_inserting = {} -- editor window -> true when <A-e> left it in Insert mode
local last_terminal -- buffer of the terminal used last
local shows = {} -- terminal buffer -> function that shows it the owner's way

local function floating(win)
	return vim.api.nvim_win_get_config(win).relative ~= ""
end

local function is_terminal(buf)
	return vim.bo[buf].buftype == "terminal"
end

local function is_editor(win)
	return vim.api.nvim_win_is_valid(win) and not floating(win) and not is_terminal(vim.api.nvim_win_get_buf(win))
end

local function record()
	local win = vim.api.nvim_get_current_win()
	if floating(win) then
		return
	end
	local buf = vim.api.nvim_win_get_buf(win)
	if is_terminal(buf) then
		last_terminal = buf
	else
		seq = seq + 1
		entered[win] = seq
	end
end

function M.setup()
	local group = vim.api.nvim_create_augroup("utils_jump", { clear = true })
	vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter", "TermOpen" }, {
		group = group,
		desc = "Jump: remember the last editor window and terminal",
		callback = record,
	})
	vim.api.nvim_create_autocmd("WinClosed", {
		group = group,
		desc = "Jump: forget closed windows",
		callback = function(ev)
			local win = tonumber(ev.match)
			entered[win], left_inserting[win] = nil, nil
		end,
	})
	record()
end

--- Tell <A-e> how to show a terminal when it's hidden (default: a vsplit).
---@param buf integer terminal buffer
---@param show fun() shows and focuses it
function M.register(buf, show)
	shows[buf] = show
end

--- The editor window entered last, in `tab` if given.
---@param tab? integer
---@return integer?
function M.last_editor(tab)
	local best
	for win, at in pairs(entered) do
		if is_editor(win) and (not tab or vim.api.nvim_win_get_tabpage(win) == tab) then
			if not best or at > entered[best] then
				best = win
			end
		end
	end
	return best
end

--- The terminal to jump to: the one used last, else any running one.
local function terminal()
	if last_terminal and vim.api.nvim_buf_is_valid(last_terminal) then
		return last_terminal
	end
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and is_terminal(buf) then
			return buf
		end
	end
end

local function to_editor()
	local win = M.last_editor(vim.api.nvim_get_current_tabpage()) or M.last_editor()
	if not win then
		return vim.notify("Jump: no editor window to go back to", vim.log.levels.INFO)
	end
	vim.api.nvim_set_current_win(win)
	if left_inserting[win] then
		left_inserting[win] = nil
		-- Scheduled: issued while still in Terminal mode, it would be lost.
		vim.schedule(vim.cmd.startinsert)
	else
		vim.cmd.stopinsert()
	end
end

local function to_terminal()
	local buf = terminal()
	if not buf then
		return vim.notify("Jump: no terminal yet (<C-n> opens a shell, <leader>ac Claude)", vim.log.levels.INFO)
	end
	left_inserting[vim.api.nvim_get_current_win()] = vim.fn.mode() == "i" or nil
	local here = vim.tbl_filter(function(win)
		return vim.api.nvim_win_get_tabpage(win) == vim.api.nvim_get_current_tabpage()
	end, vim.fn.win_findbuf(buf))[1]
	if here then
		vim.api.nvim_set_current_win(here)
	elseif shows[buf] then
		shows[buf]()
	else
		vim.cmd.vsplit()
		vim.api.nvim_win_set_buf(0, buf)
	end
	vim.cmd.startinsert()
end

--- <A-e>: editor <-> terminal.
function M.toggle()
	if is_terminal(vim.api.nvim_get_current_buf()) then
		to_editor()
	else
		to_terminal()
	end
end

return M
