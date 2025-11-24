require'nvim-treesitter'.setup {
  -- Directory to install parsers and queries to
  install_dir = vim.fn.stdpath('data') .. '/site'
}
require'nvim-treesitter'.install { 
	'rust', 
	'javascript', 
	'zig',
	'c',
	'cpp',
	'python',
	'java',
	'json',
	'meson',
	'zsh',
	'lua',
}

vim.treesitter.start()
vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
