-- Minimal native LSP setup for Neovim 0.11+

-- Basic on_attach, like keymaps etc
local function on_attach(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local opts = { noremap = true, silent = true }

  buf_set_keymap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
  buf_set_keymap("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opts)
  buf_set_keymap("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
  -- buf_set_keymap("n", "K",  "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
  -- buf_set_keymap("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
  -- buf_set_keymap("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>", opts)
  -- buf_set_keymap("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>", opts)
end

-- default capabilities config
local capabilities = vim.lsp.protocol.make_client_capabilities()

-- Helper to register+enable a server using the new API
local function register_server(name, config)
  vim.lsp.config(name, config)
  vim.lsp.enable(name)
end

-- pyright for Python
register_server("pyright", {
  cmd = { "pyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_dir = function(fname)
    return vim.fs.dirname(vim.fs.find({ "pyproject.toml", "setup.cfg", "requirements.txt", ".git" }, { path = fname })[1] or fname)
  end,
  -- attach our on_attach and capabilities as defaults used when a client is created
  on_attach = on_attach,
  capabilities = capabilities,
})

-- clangd for C/C++
register_server("clangd", {
  cmd = { "clangd" },
  filetypes = { "c", "cpp", "objc", "objcpp" },
  root_dir = function(fname)
    return vim.fs.dirname(vim.fs.find({ "compile_commands.json", "compile_flags.txt", "meson.build", "CMakeLists.txt", ".git" }, { path = fname })[1] or fname)
  end,
  on_attach = on_attach,
  capabilities = capabilities,
})

-- Optional: define a simple "fallback" language server config (demo only)
-- vim.lsp.config("demo_dummy", { cmd = { "true" }, filetypes = { "txt" } })
-- vim.lsp.enable("demo_dummy")

