-- Claude Code keymaps, as a lazy.nvim `keys` list: the claudecode.nvim spec
-- uses this table directly. Add a key here and nowhere else; the <leader>a
-- group is named in ui/which_key.lua. Keys inside the Claude terminal live in
-- terminal.lua, the picker key (<A-c>) in ui/snacks.lua, and <A-e> (jump
-- between editor and Claude/shell) in configs/keymaps/terminal.lua.

-- File trees whose selection <leader>as references (the ones claudecode.nvim
-- reads). snacks_picker_list is the snacks explorer and the list window of
-- every snacks picker.
local trees = { "snacks_picker_list", "netrw" }

--- A references.lua function, required on use (the plugin may not be loaded
--- yet). They type @file#Lx-y into Claude's prompt at its cursor.
local function ref(name)
	return function()
		require("plugins.configs.tools.claudecode.references")[name]()
	end
end

--- A diffs.lua function, required on use (the plugin may not be loaded yet).
local function diffs(name)
	return function()
		require("plugins.configs.tools.claudecode.diffs")[name]()
	end
end

return {
	{ "<leader>ac", "<cmd>ClaudeCode<CR>", desc = "Claude: toggle window" },
	{ "<leader>af", "<cmd>ClaudeCodeFocus<CR>", desc = "Claude: focus window" },
	{ "<leader>ar", "<cmd>ClaudeCode --resume<CR>", desc = "Claude: resume a past conversation" },
	{ "<leader>aC", "<cmd>ClaudeCode --continue<CR>", desc = "Claude: continue the last conversation" },
	{ "<leader>am", "<cmd>ClaudeCodeSelectModel<CR>", desc = "Claude: start with a chosen model" },
	{ "<leader>ab", ref("file"), desc = "Claude: reference this file in the prompt" },
	{ "<leader>as", ref("selection"), mode = "x", desc = "Claude: reference the selected lines" },
	{ "<leader>as", ref("tree"), ft = trees, desc = "Claude: reference the file(s) under the cursor" },
	{ "<leader>as", ref("tree"), mode = "x", ft = trees, desc = "Claude: reference the selected files" },
	-- Diffs: these work from any window (diffs.lua). Inside the proposed
	-- buffer, :w / <C-s> / <C-x> also accept and :q / <C-q> reject.
	{ "<leader>aa", diffs("accept"), desc = "Claude: accept the diff" },
	{ "<leader>ad", diffs("reject"), desc = "Claude: reject the diff" },
	{ "<leader>aj", diffs("jump"), desc = "Claude: jump to a waiting diff" },
	{ "<leader>ax", "<cmd>ClaudeCodeCloseAllDiffs<CR>", desc = "Claude: close all pending diffs" },
	{ "<leader>aS", "<cmd>ClaudeCodeStatus<CR>", desc = "Claude: connection status" },
	{
		"<leader>ao",
		function()
			require("plugins.configs.tools.claudecode.toggles").menu()
		end,
		desc = "Claude: options (quick toggles)",
	},
}
