local status_ok, configs = pcall(require, "nvim-treesitter.configs")
if not status_ok then
	return -- Fails silently if the plugin isn't downloaded yet
end

configs.setup({
	ensure_installed = {
		"rust",
		"javascript",
		"zig",
		"c",
		"cpp",
		"python",
		"java",
		"json",
		"meson",
		-- "zsh",
		"lua",
		"matlab",
		"markdown",
		"markdown_inline",
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

vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
