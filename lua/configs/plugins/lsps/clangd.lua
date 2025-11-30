return {
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
    "--offset-encoding=utf-8",
  },
  filetypes = { "c", "cpp" },
  root_markers = { ".clangd", "compile_commands.json", ".git" },
}

