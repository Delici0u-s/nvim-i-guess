-- Claude Code <-> Neovim bridge (coder/claudecode.nvim). Config and settings:
-- lua/plugins/configs/tools/claudecode/.
return {
	{
		"coder/claudecode.nvim",
		dependencies = { "folke/snacks.nvim" },
		-- Started with Neovim (not on first key), so a `claude` in another
		-- terminal can connect with /ide at any time.
		event = "VeryLazy",
		keys = require("plugins.configs.tools.claudecode.keymaps"),
		config = function()
			require("plugins.configs.tools.claudecode")()
		end,
	},
}
