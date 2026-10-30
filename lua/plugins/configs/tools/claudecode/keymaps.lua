-- Claude Code keymaps, as a lazy.nvim `keys` list: the claudecode.nvim spec
-- uses this table directly. Add a key here and nowhere else; the <leader>a
-- group is named in ui/which_key.lua. Keys inside the Claude terminal live in
-- terminal.lua, the picker key (<A-c>) in ui/snacks.lua.

-- File trees whose selection <leader>as sends (the ones claudecode.nvim's
-- :ClaudeCodeTreeAdd reads). snacks_picker_list is the snacks explorer and
-- the list window of every snacks picker.
local trees = { "snacks_picker_list", "netrw" }

local function add_buffer()
	local file = vim.api.nvim_buf_get_name(0)
	if file == "" or vim.bo.buftype ~= "" then
		return vim.notify("Claude: this buffer isn't a file", vim.log.levels.WARN)
	end
	vim.cmd.ClaudeCodeAdd(vim.fn.fnameescape(file))
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
	{ "<leader>ab", add_buffer, desc = "Claude: add this file to the context" },
	{ "<leader>as", "<cmd>ClaudeCodeSend<CR>", mode = "x", desc = "Claude: send the selection" },
	{ "<leader>as", "<cmd>ClaudeCodeTreeAdd<CR>", ft = trees, desc = "Claude: add the file(s) under the cursor" },
	{
		"<leader>as",
		"<cmd>ClaudeCodeTreeAdd<CR>",
		mode = "x",
		ft = trees,
		desc = "Claude: add the selected files",
	},
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
