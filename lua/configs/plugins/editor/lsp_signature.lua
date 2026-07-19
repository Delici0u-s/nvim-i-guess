return function()
	require("lsp_signature").setup({
		bind = true,
		floating_window = true,
		hint_enable = false, -- VS Code doesn't use inline hints
		handler_opts = {
			border = "rounded",
		},
	})
end
