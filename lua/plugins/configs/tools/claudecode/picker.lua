-- Snacks picker action: reference the picked items in Claude's prompt (<A-c>
-- in any picker, bound in ui/snacks.lua). Several with <Tab>, else the one
-- under the cursor. Items with a position (grep, diagnostics, LSP) reference
-- that line.
local M = {}

---@param picker snacks.Picker
function M.add(picker)
	local refs = {}
	for _, item in ipairs(picker:selected({ fallback = true })) do
		local path = Snacks.picker.util.path(item)
		if path then
			refs[#refs + 1] = { path = path, first = item.pos and item.pos[1] }
		end
	end
	if #refs == 0 then
		return vim.notify("Claude: nothing here is a file", vim.log.levels.WARN)
	end
	picker:close()
	require("plugins.configs.tools.claudecode.references").add(refs)
end

return M
