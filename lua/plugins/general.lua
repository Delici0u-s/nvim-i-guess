return {
{
	"nvim-treesitter/nvim-treesitter",
	lazy = false,
	branch = 'main',
	build = ':TSUpdate',

},
{
	"neovim/nvim-lspconfig",
	config = function()
	require("conf_lspconfig")
	end,
},
}

