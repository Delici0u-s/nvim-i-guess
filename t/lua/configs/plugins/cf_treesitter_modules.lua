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

	local SKIP = {
		expression_statement = true,
		parenthesized_expression = true,
		-- add more as you discover them via :InspectTree
	}

	local orig = vim.keymap -- already bound by treesitter-modules
	vim.keymap.set("v", "<C-w>", function()
		-- keep pressing the internal incremental until we land on a non-skipped node
		local ts_inc = function()
			vim.api.nvim_feedkeys(
				vim.api.nvim_replace_termcodes(
					-- call the actual treesitter-modules mapping directly
					"<Plug>(treesitter-modules-node-incremental)",
					true,
					false,
					true
				),
				"x",
				false
			)
		end
		-- fallback: just trigger directly
		require("nvim-treesitter.incremental_selection").node_incremental()
	end, {})
end
