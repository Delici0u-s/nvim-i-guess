return {
  cmd = { "lua-language-server" },   -- or absolute path if needed

  filetypes = { "lua" },

  root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },

  settings = {
    Lua = {
      runtime = {
        version = "LuaJIT",      -- Neovim uses LuaJIT
        path = vim.split(package.path, ";"),
      },

      diagnostics = {
        globals = { "vim" },     -- Recognize `vim` global
      },

      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
        },
      },

      completion = {
        callSnippet = "Replace",
      },
    },
  },
}


