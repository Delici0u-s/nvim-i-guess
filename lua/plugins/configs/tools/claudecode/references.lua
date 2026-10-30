-- Reference files and lines in Claude's prompt: types `@path` / `@path#L5-9`
-- into Claude's input at its cursor, without sending, as if you typed it.
-- (claudecode.nvim's own "add" commands send a mention that Claude Code
-- places itself, which lands oddly once you've typed something.)
--
-- Used by <leader>ab / <leader>as (keymaps.lua) and <A-c> in pickers
-- (picker.lua). When there's no Claude terminal in Neovim (not started yet, or
-- `claude` runs elsewhere), it falls back to those mentions, which start Claude
-- and wait for it to connect.
local M = {}

---@class ClaudeRef
---@field path string
---@field first? integer first line (1-based)
---@field last? integer last line

--- `@path`, `@path#L5` or `@path#L5-9`; relative to the working directory
--- (where Claude runs) when inside it.
---@param ref ClaudeRef
function M.format(ref)
	local path = vim.fn.fnamemodify(ref.path, ":p")
	local cwd = vim.fn.getcwd() .. "/"
	if vim.startswith(path, cwd) then
		path = path:sub(#cwd + 1)
	end
	local lines = ""
	if ref.first then
		lines = "#L" .. ref.first .. ((ref.last and ref.last ~= ref.first) and ("-" .. ref.last) or "")
	end
	return "@" .. path .. lines
end

---@param refs ClaudeRef[]
function M.add(refs)
	if #refs == 0 then
		return vim.notify("Claude: nothing to reference here", vim.log.levels.WARN)
	end
	local claudecode = require("claudecode")
	local terminal = require("claudecode.terminal")
	if not terminal.get_active_terminal_bufnr() then
		for _, ref in ipairs(refs) do
			-- The plugin counts lines from 0.
			local first = ref.first and ref.first - 1
			local last = ref.first and (ref.last or ref.first) - 1
			claudecode.send_at_mention(ref.path, first, last, "reference")
		end
		return
	end
	-- Spaces around, so it never sticks to a word typed before or after it.
	local text = " " .. table.concat(vim.tbl_map(M.format, refs), " ") .. " "
	if not terminal.send_to_terminal(text, { submit = false }) then
		return
	end
	if claudecode.state.config.focus_after_send then
		terminal.open()
	else
		terminal.ensure_visible()
	end
end

--- This buffer's file.
function M.file()
	local path = vim.api.nvim_buf_get_name(0)
	if path == "" or vim.bo.buftype ~= "" then
		return vim.notify("Claude: this buffer isn't a file", vim.log.levels.WARN)
	end
	M.add({ { path = path } })
end

--- The selected lines of this buffer's file (Visual mode).
function M.selection()
	local path = vim.api.nvim_buf_get_name(0)
	if path == "" or vim.bo.buftype ~= "" then
		return vim.notify("Claude: this buffer isn't a file", vim.log.levels.WARN)
	end
	local a, b = vim.fn.line("v"), vim.fn.line(".")
	vim.cmd.normal({ vim.keycode("<Esc>"), bang = true })
	M.add({ { path = path, first = math.min(a, b), last = math.max(a, b) } })
end

--- The file(s) under the cursor, marked or selected in a file tree
--- (snacks explorer/picker list, netrw), read by claudecode.nvim.
function M.tree()
	local visual = vim.fn.mode():find("^[vV\22]") ~= nil
	local files, err
	if visual then
		local vc = require("claudecode.visual_commands")
		files, err = vc.get_files_from_visual_selection(vc.capture_visual_selection_data())
		vim.cmd.normal({ vim.keycode("<Esc>"), bang = true })
	else
		files, err = require("claudecode.integrations").get_selected_files_from_tree()
	end
	if not files then
		return vim.notify("Claude: " .. tostring(err), vim.log.levels.WARN)
	end
	M.add(vim.tbl_map(function(path)
		return { path = path }
	end, files))
end

return M
