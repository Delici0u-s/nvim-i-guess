return {
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		branch = "main",
		build = ":TSUpdate",
	},
	-- {
	-- 	"neovim/nvim-lspconfig",
	-- 	lazy = false;
	-- 	config = function()
	-- 	  require("configs.plugins.cf_lspconfig")()
	-- 	end
	-- },
	{
		"L3MON4D3/LuaSnip",
		-- follow latest release.
		version = "v2.4.1", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
		-- install jsregexp (optional!).
		build = "make install_jsregexp",
	},
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",
			"saadparwaiz1/cmp_luasnip",
			-- "rafamadriz/friendly-snippets",
		},
		config = function()
			-- local cmp_caps = require("cmp_nvim_lsp").default_capabilities()
			-- vim.lsp.config("*", { capabilities = cmp_caps })
			-- full config shown below (copy it into here or require a separate file)
			require("configs.plugins.cf_cmp")()
		end,
	},
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
	},
	{
		"luukvbaal/statuscol.nvim",
		config = function()
			require("configs.plugins.cf_statuscol")()
		end,
	},
	{
		"folke/lazydev.nvim",
		ft = "lua", -- only load on lua files
		opts = {
			library = {
				-- See the configuration section for more details
				-- Load luvit types when the `vim.uv` word is found
				{
					path = "${3rd}/luv/library",
					words = { "vim%.uv" },
				},
			},
		},
	},
	{
		"williamboman/mason.nvim",
		lazy = false,
		config = function()
			require("mason").setup()
		end,
	},
	{
		"mason-org/mason-lspconfig.nvim",
		opts = {},
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
			"neovim/nvim-lspconfig",
		},
	},
	{
		"nvim-telescope/telescope.nvim",
		tag = "v0.2.0",
		dependencies = { "nvim-lua/plenary.nvim" },
	},
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
	},
	{
		"stevearc/conform.nvim",
		opts = {},
		config = function()
			require("configs.plugins.cf_conform")()
		end,
	},
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {},
	},
	{
		"mfussenegger/nvim-dap",
		config = function()
			require("configs.plugins.cf_dap")()
		end,
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		---@module "ibl"
		---@type ibl.config
		opts = {},
		config = function()
			require("configs.plugins.cf_indent_blankline")()
		end,
	},
}
