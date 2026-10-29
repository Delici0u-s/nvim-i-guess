-- Claude Code keymaps, as a lazy.nvim `keys` list: the claudecode.nvim spec
-- uses this table directly. Add a key here and nowhere else; the <leader>a
-- group is named in ui/which_key.lua.
return {
	{ "<leader>ac", "<cmd>ClaudeCode<CR>", desc = "Claude: toggle window" },
	{
		"<leader>ao",
		function()
			require("plugins.configs.tools.claudecode.toggles").menu()
		end,
		desc = "Claude: options (quick toggles)",
	},
}
