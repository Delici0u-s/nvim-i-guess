return {
	-- ===========================================================================
	-- TREESITTER
	-- ===========================================================================
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false, -- highlighting must exist for the first buffer drawn
		branch = "master", -- cf_tree_sitter.lua uses master-only API
		build = ":TSUpdate",
		config = function()
			require("plugins.configs.lang.treesitter")()
		end,
	},

	-- ===========================================================================
	-- LSP / MASON
	-- ===========================================================================
	{
		-- Not lazy: configs/general/lsp_capabilities.lua requires this at startup
		-- to build the global capabilities table before any server is enabled.
		-- It is a small module that returns a table; there is no real cost.
		"hrsh7th/cmp-nvim-lsp",
		lazy = false,
		priority = 900,
	},
	{
		"mason-org/mason.nvim",
		cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonLog" },
		opts = {},
	},
	{
		"mason-org/mason-lspconfig.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"mason-org/mason.nvim",
			"neovim/nvim-lspconfig",
		},
		config = function()
			require("plugins.configs.lang.mason")()
		end,
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		event = "VeryLazy",
		dependencies = { "mason-org/mason.nvim" },
		config = function()
			require("plugins.configs.lang.mason_tools")()
		end,
	},
	{
		"folke/lazydev.nvim",
		ft = "lua",
		config = function()
			require("plugins.configs.lang.lazydev")()
		end,
	},

	-- ===========================================================================
	-- COMPLETION / SNIPPETS
	-- ===========================================================================
	{
		"L3MON4D3/LuaSnip",
		version = "v2.4.1",
		build = "make install_jsregexp",
		event = "InsertEnter",
		config = function()
			require("plugins.configs.editor.luasnip")()
		end,
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
			"L3MON4D3/LuaSnip",
		},
		config = function()
			require("plugins.configs.editor.cmp")()
		end,
	},
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {},
	},
	{
		"ray-x/lsp_signature.nvim",
		event = "InsertEnter",
		config = function()
			require("plugins.configs.editor.lsp_signature")()
		end,
	},

	-- ===========================================================================
	-- FORMATTING
	-- ===========================================================================
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		config = function()
			require("plugins.configs.editor.conform")()
		end,
	},

	-- ===========================================================================
	-- UI
	-- ===========================================================================
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false, -- owns vim.notify and the picker; must be up early
		config = function()
			require("plugins.configs.ui.snacks")()
		end,
	},
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		event = "VeryLazy",
		config = function()
			require("plugins.configs.ui.lualine")()
		end,
	},
	{
		"luukvbaal/statuscol.nvim",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("plugins.configs.ui.statuscol")()
		end,
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("plugins.configs.ui.indent_blankline")()
		end,
	},
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			-- Popup delay is independent of 'timeoutlen'. Keep it long enough
			-- that which-key never appears during normal fast typing on the
			-- <C-t>/<C-h>/<C-v>/<C-e> prefixes -- it only shows if you actually
			-- pause. Set to 0 if you want it to appear immediately instead.
			delay = 500,
		},
	},
	{
		"kevinhwang91/nvim-ufo",
		dependencies = { "kevinhwang91/promise-async" },
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("plugins.configs.ui.ufo")()
		end,
	},
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" },
		ft = { "markdown", "quarto" },
		config = function()
			require("plugins.configs.ui.render_markdown")()
		end,
	},
	{
		"stevearc/dressing.nvim",
		event = "VeryLazy",
	},

	-- ===========================================================================
	-- EDITING
	-- ===========================================================================
	{
		"Delici0u-s/typing-transformer.nvim",
		event = "InsertEnter",
		opts = {
			global = {
				'"  |)"  -> ")|"',
				'"cosnt |" -> "const |"',
			},
			filetype = {
				lua = {
					'"test|" -> "successful|"',
					'"!lfn|" -> "local function |"',
				},
			},
		},
	},

	-- ===========================================================================
	-- DEBUGGING
	-- ===========================================================================
	{
		"mfussenegger/nvim-dap",
		-- Must list every key defined in dap/keymaps.lua: a key not listed here
		-- does nothing until some other <leader>d key loads the plugin first.
		keys = {
			{ "<leader>dt", desc = "DAP: toggle breakpoint" },
			{ "<leader>dc", desc = "DAP: continue" },
			{ "<leader>di", desc = "DAP: step into" },
			{ "<leader>do", desc = "DAP: step over" },
			{ "<leader>du", desc = "DAP: step out" },
			{ "<leader>dr", desc = "DAP: open REPL" },
			{ "<leader>dl", desc = "DAP: run last" },
			{ "<leader>dq", desc = "DAP: terminate" },
			{ "<leader>db", desc = "DAP: list breakpoints" },
			{ "<leader>de", desc = "DAP: exception breakpoints" },
		},
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"nvim-neotest/nvim-nio",
			"jay-babu/mason-nvim-dap.nvim",
			"theHamsta/nvim-dap-virtual-text",
		},
		config = function()
			require("plugins.configs.tools.dap.init")()
		end,
	},

	-- ===========================================================================
	-- JUPYTER / IMAGES
	-- ===========================================================================
	{
		"3rd/image.nvim",
		ft = { "markdown", "quarto", "python", "ipynb" },
		config = function()
			require("plugins.configs.tools.image")()
		end,
	},
	{
		"kiyoon/jupynium.nvim",
		build = "pip3 install --user .",
		cmd = {
			"JupyniumStartAndAttachToServer",
			"JupyniumStartSync",
			"JupyniumAttachToServer",
			"JupyniumKernelSelect",
		},
		ft = { "python", "ipynb" },
		dependencies = { "rcarriga/nvim-notify" },
		config = function()
			require("plugins.configs.tools.jupynium")()
		end,
	},
}
