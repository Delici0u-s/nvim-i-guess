-- which-key: shows what a pending prefix can be followed by.
--
-- This file is the one place prefixes get their names. Individual keys need
-- no registration here: which-key reads each mapping's `desc`. When you start
-- a new prefix, name it below (and in overview.md's prefix table).
return function()
	local wk = require("which-key")
	wk.setup({
		-- Popup delay is independent of 'timeoutlen'. Keep it long enough that
		-- which-key never appears during normal fast typing on the
		-- <C-t>/<C-h>/<C-v>/<C-e> prefixes -- it only shows if you actually
		-- pause. Set to 0 if you want it to appear immediately instead.
		delay = 500,
		spec = {
			{ "<leader>a", group = "AI / Claude Code", mode = { "n", "v" } },
			{ "<leader>d", group = "Debug", mode = { "n", "v" } },
			{ "<leader>t", group = "Tabs / toggles" },
			{ "<leader>tt", group = "Trouble" },
			{ "<leader>j", group = "Jupyter" },
			{ "<leader>jl", group = "Load notebook tab" },
			{ "<leader>g", group = "Git" },
			{ "<C-t>", group = "Pickers" },
			{ "<C-e>", group = "Explore" },
			{ "<C-h>", group = "Horizontal split" },
			{ "<C-v>", group = "Vertical split" },
			{ "<C-r>", group = "Markdown rendering" },
			{ "tg", group = "LSP jump in new tab" },
		},
	})

	require("utils.keybinds").map("n", "<leader>?", function()
		wk.show({ global = false })
	end, { desc = "Keys: keymaps for this buffer" })
end
