return function()
    local lspconfig = require("lspconfig")
    local lsp = require("configs.plugins.cf_lsp")

    require("mason-lspconfig").setup({
        automatic_enable = true,
        automaitc_setup = true,
        ensure_installed = {
            -- Core
            "lua_ls",
            "pyright",
            "clangd",
            "jdtls",

            -- General
            "bashls",
            "jsonls",
            "yamlls",
            "marksman",
            "cmake",
            "mesonlsp",

            -- Web
            "ts_ls",
            "html",
            "cssls",
            "eslint",

            -- DevOps
            "dockerls",
            "terraformls",
        },
    })
end
