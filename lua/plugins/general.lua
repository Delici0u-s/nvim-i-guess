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
        ft = "lua",
        config = function()
            require("configs.plugins.cf_lazydev")()
        end,
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
        config = function()
            require("configs.plugins.cf_mason")()
        end,
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
        "williamboman/mason.nvim",
        config = true,
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
    {
        "ray-x/lsp_signature.nvim",
        event = "InsertEnter",
        opts = {},
        config = require("configs.plugins.cf_lsp_signature")
    },
    -- {
    --     "azratul/live-share.nvim",
    --     dependencies = {
    --         "jbyuki/instant.nvim",
    --     },
    --     config = require("configs.plugins.cf_live_share")
    -- },
    {
        'MeanderingProgrammer/render-markdown.nvim',
        dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' }, -- if you use the mini.nvim suite
        -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },        -- if you use standalone mini plugins
        -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
        ---@module 'render-markdown'
        ---@type render.md.UserConfig
        opts = {},
        config = require("configs.plugins.cf_render_markdown")
    },
    -- {
    --     'sontungexpt/better-diagnostic-virtual-text',
    --     config = function(_)
    --         require('configs.plugins.cf_better_diagnostic_virtual_text')()
    --     end
    -- },
    {
        "mfussenegger/nvim-dap",
        event = "VeryLazy",
        dependencies = {
            "rcarriga/nvim-dap-ui",
            "nvim-neotest/nvim-nio",
            "jay-babu/mason-nvim-dap.nvim",
            "theHamsta/nvim-dap-virtual-text",
        },

        config = require("configs.plugins.dap.init")
    },
    { "WhoIsSethDaniel/mason-tool-installer.nvim" },
}
