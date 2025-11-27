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
{
	"L3MON4D3/LuaSnip",
	-- follow latest release.
	version = "v2.4.1", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
	-- install jsregexp (optional!).
	build = "make install_jsregexp"
},
{
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp", 
    "hrsh7th/cmp-buffer",    
    "hrsh7th/cmp-path",       
    "hrsh7th/cmp-cmdline",     
    -- "saadparwaiz1/cmp_luasnip",
    -- "rafamadriz/friendly-snippets",
  },
  config = function()
    -- full config shown below (copy it into here or require a separate file)
    require("configs.plugins.cf_cmp")()
  end,
},
}

