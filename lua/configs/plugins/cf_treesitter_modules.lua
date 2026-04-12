return function()
	require("treesitter-modules").setup({
		incremental_selection = {
			enable = true,
			keymaps = {
				init_selection = "<CR>",
				node_incremental = "<C-w>",
				node_decremental = "<C-S-w>",
				scope_incremental = false,
			},
		},
	})
end
