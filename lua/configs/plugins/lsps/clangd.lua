-- Force C filetype for .h if needed
vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
    pattern = "*.h",
    callback = function()
        vim.bo.filetype = "c"
    end
})

return {
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
    "--offset-encoding=utf-8",
  },
  filetypes = { "c", "cpp" },
}

