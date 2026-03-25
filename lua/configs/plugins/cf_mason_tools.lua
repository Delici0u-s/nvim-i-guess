-- in cf_mason.lua or a new cf_mason_tools.lua
require("mason-tool-installer").setup({
    ensure_installed = {
        -- formatters for conform
        "ruff", -- covers ruff_format
        "black",
        "isort",
        "stylua", -- lua (you already have this in conform)
        "clang-format",
    },
    auto_update = false,
    run_on_start = true,
})
