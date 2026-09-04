return function()
	-- NOTE: this is nvim-treesitter `master` branch API. The `main` branch
	-- removed nvim-treesitter.configs entirely; do not bump the branch in
	-- lua/plugins/general.lua without rewriting this file.
	require("nvim-treesitter.configs").setup({
		ensure_installed = {
			"c",
			"cpp",
			"rust",
			"zig",
			"python",
			"java",
			"javascript",
			"lua",
			"json",
			"meson",
			"matlab",
			"markdown",
			"markdown_inline",
			"bash",
			"vim",
			"vimdoc",
			"query",
		},
		sync_install = false,
		auto_install = true,
		highlight = {
			enable = true,
			additional_vim_regex_highlighting = false,
		},
		indent = {
			enable = true,
		},
	})

	-- Fold expression must be set per-window, on buffers that actually have a
	-- parser. Setting vim.wo at startup only ever configured the first scratch
	-- buffer. nvim-ufo drives folding when it is loaded; this is the fallback
	-- for buffers ufo skips.
	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("ts_folding", { clear = true }),
		callback = function(args)
			if not pcall(vim.treesitter.get_parser, args.buf) then
				return
			end
			vim.wo.foldmethod = "expr"
			vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
		end,
	})
end
