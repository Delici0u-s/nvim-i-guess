require("mason-lspconfig").setup {
  automatic_enable = true,
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
}

