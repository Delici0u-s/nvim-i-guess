-- Snacks picker action: add the picked items to Claude's context (<A-c> in
-- any picker, bound in ui/snacks.lua). Several with <Tab>, else the one under
-- the cursor. Items with a position (grep, diagnostics, LSP) send that line.
local M = {}

---@param picker snacks.Picker
function M.add(picker)
	local ok, claudecode = pcall(require, "claudecode")
	if not ok then
		return vim.notify("Claude: claudecode.nvim isn't loaded", vim.log.levels.WARN)
	end
	local sent = 0
	for _, item in ipairs(picker:selected({ fallback = true })) do
		local path = Snacks.picker.util.path(item)
		if path then
			local line = item.pos and item.pos[1] - 1 -- the plugin counts from 0
			if claudecode.send_at_mention(path, line, line, "picker") then
				sent = sent + 1
			end
		end
	end
	if sent == 0 then
		return vim.notify("Claude: nothing here is a file", vim.log.levels.WARN)
	end
	picker:close()
	vim.notify(("Claude: added %d item%s"):format(sent, sent == 1 and "" or "s"))
end

return M
