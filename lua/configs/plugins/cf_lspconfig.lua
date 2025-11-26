-- wrap everything so it can be loaded in plugins.general in the lspconfig func
return function()
-- LSP configuration using utility functions and flexible server customization

local utils = require("utils.path")

-- Basic on_attach: keymaps
local function on_attach(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local opts = { noremap = true, silent = true }

  buf_set_keymap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
  buf_set_keymap("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opts)
  buf_set_keymap("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
  -- add more mappings if needed
end

-- Default capabilities
local capabilities = vim.lsp.protocol.make_client_capabilities()

-- Helper to register + enable server
local function register_server(name, config)
  vim.lsp.config(name, config)
  vim.lsp.enable(name)
end

-- Shared defaults (can be overridden per server)
local default_config = {
  on_attach = on_attach,
  capabilities = capabilities,
}

-- Server table: each server can override any defaults or add new fields
local servers = {
  pyright = {
    cmd = { "pyright-langserver", "--stdio" },
    filetypes = { "python" },
    root_patterns = { "pyproject.toml", "setup.cfg", "requirements.txt", ".git" },
    -- custom per-server fields can be added here:
    settings = { python = { analysis = { typeCheckingMode = "off" } } },
  },

  clangd = {
    cmd = { "clangd" },
    filetypes = { "c", "cpp", "objc", "objcpp" },
    root_patterns = { "compile_commands.json", "compile_flags.txt", "meson.build", "CMakeLists.txt", ".git" },
    -- example of adding clangd-specific flags
    init_options = { clangdFileStatus = true },
  },

  -- add more servers here
}

-- Register servers, merging defaults with per-server config
for name, s in pairs(servers) do
  local cfg = vim.tbl_deep_extend("force", {
    cmd = s.cmd,
    filetypes = s.filetypes,
    root_dir = utils.root_dir_factory(s.root_patterns or { ".git" }),
  }, default_config, s)  -- merge per-server config last to allow overrides
  register_server(name, cfg)
end

end
