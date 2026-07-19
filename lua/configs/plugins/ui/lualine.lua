return function()
	-- theme = "auto" derives colours from the active colorscheme. The previous
	-- config required lualine.themes.gruvbox, which is not an installed plugin,
	-- so lualine was never configured at all.
	require("lualine").setup({
		options = {
			icons_enabled = true,
			theme = "auto",
			globalstatus = true, -- single statusline for all splits
		},
		sections = {
			lualine_a = { "mode" },
			lualine_b = { "branch", "diff", "diagnostics" },
			lualine_c = { { "filename", path = 1 } },
			lualine_x = { "encoding", "fileformat", "filetype" },
			lualine_y = { "progress" },
			lualine_z = { "location" },
		},
		extensions = { "lazy", "mason", "nvim-dap-ui", "quickfix" },
	})
end
