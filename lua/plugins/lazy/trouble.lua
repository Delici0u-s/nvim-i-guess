-- example that more files are possible, not just the general. I have only been too lazy to divide into more files
return {
	{
		"folke/trouble.nvim",
		opts = {}, -- for default options, refer to the configuration section for custom setup.
		cmd = "Trouble",
		keys = {
			{
				"<leader>ttx",
				"<cmd>Trouble diagnostics toggle<cr>",
				desc = "Trouble: diagnostics",
			},
			{
				"<leader>ttX",
				"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
				desc = "Trouble: buffer diagnostics",
			},
			{
				"<leader>tts",
				"<cmd>Trouble symbols toggle focus=false<cr>",
				desc = "Trouble: symbols",
			},
			{
				"<leader>ttl",
				"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
				desc = "Trouble: LSP definitions / references / ...",
			},
			{
				"<leader>ttL",
				"<cmd>Trouble loclist toggle<cr>",
				desc = "Trouble: location list",
			},
			{
				"<leader>ttQ",
				"<cmd>Trouble qflist toggle<cr>",
				desc = "Trouble: quickfix list",
			},
		},
	},
}
