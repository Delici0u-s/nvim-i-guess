-- Global defaults for all LSP servers

vim.lsp.config("*", {

  -- Root detection shared across all LSPs
  root_markers = {
    -- { },  -- equal priority group
    ".git",
  },

  -- Capabilities: augment all servers with semantic tokens
  capabilities = {
    textDocument = {
      semanticTokens = {
        multilineTokenSupport = true,
      },
    },
  },

  -- Default formatting behavior (can be overridden)
  -- on_attach = function(client, bufnr)
  --   -- Example: Format on save if supported
  --   if client:supports_method("textDocument/formatting") then
  --     vim.api.nvim_create_autocmd("BufWritePre", {
  --       buffer = bufnr,
  --       group = vim.api.nvim_create_augroup("LSP.format." .. bufnr, {}),
  --       callback = function()
  --         vim.lsp.buf.format({ bufnr = bufnr, timeout_ms = 800 })
  --       end,
  --     })
  --   end
  --
  --   -- Keymaps (global for all servers)
  --   local map = function(lhs, rhs)
  --     vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true })
  --   end
  --
  --   map("gd", vim.lsp.buf.definition)
  --   map("gr", vim.lsp.buf.references)
  --   map("K",  vim.lsp.buf.hover)
  --   map("<leader>rn", vim.lsp.buf.rename)
  --   map("<leader>ca", vim.lsp.buf.code_action)
  -- end,
  
})
