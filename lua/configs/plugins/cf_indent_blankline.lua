return function()
	local highlight = {
		"IndentStartLine",
		"IndentBlack",
		"IndentVeryDarkRed",
		"IndentDarkRed",
		"IndentMutedRed",
		"IndentRed",
		"IndentBrightRed",
		"IndentStrongRed",
	}

	local hooks = require("ibl.hooks")

	hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
		vim.api.nvim_set_hl(0, "IndentStartLine", { fg = "#1e1e1e" })
		-- almost black
		vim.api.nvim_set_hl(0, "IndentBlack", { fg = "#1E1E1E" })

		-- barely red-tinted dark
		vim.api.nvim_set_hl(0, "IndentVeryDarkRed", { fg = "#2A1C1C" })

		-- dark red
		vim.api.nvim_set_hl(0, "IndentDarkRed", { fg = "#3A1F1F" })

		-- muted red
		vim.api.nvim_set_hl(0, "IndentMutedRed", { fg = "#5A2A2A" })

		-- normal red
		vim.api.nvim_set_hl(0, "IndentRed", { fg = "#8B3A3A" })

		-- brighter red
		vim.api.nvim_set_hl(0, "IndentBrightRed", { fg = "#B44444" })

		-- strongest red (still tasteful)
		vim.api.nvim_set_hl(0, "IndentStrongRed", { fg = "#E06C75" })
	end)

	require("ibl").setup({
		indent = { highlight = highlight },
	})
end
