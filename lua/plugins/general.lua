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
	  require("configs.plugins.cf_lspconfig")()
	end
},
}

