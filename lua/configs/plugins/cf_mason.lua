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

    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        callback = function(args)
            for _, client in ipairs(vim.lsp.get_clients({ bufnr = args.buf })) do
                client.notify("workspace/didChangeWatchedFiles", {
                    changes = {
                        {
                            uri = vim.uri_from_bufnr(args.buf),
                            type = 1, -- Created or Changed
                        },
                    },
                })
            end
        end,
    })
end
