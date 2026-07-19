return function()
    vim.g.instant_username = "test_name"

    require("live-share").setup({})
end
