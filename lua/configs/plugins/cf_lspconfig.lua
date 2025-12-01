-- load specific plugins
local log = require("utils.log")

local enabled_plugins = {
  "lua_ls",
  "pyright",
  "clangd",
  -- "gibberish",
}

return function()
  local valid_lsps = {}

  -- Validate that plugin config files exist
  for _, server in ipairs(enabled_plugins) do
    local ok = pcall(require, "configs.plugins.lsps.pluginlist." .. server)
    if ok then
      table.insert(valid_lsps, server)
    else
      vim.notify("LSP config not found for configs.plugins.lsps.pluginlist." .. server, vim.log.levels.WARN)
    end
  end

  -- Load only valid LSPs
  for _, server in ipairs(valid_lsps) do
    local ok, cfg = pcall(require, "configs.plugins.lsps.pluginlist." .. server)

    if ok then
      vim.lsp.config(server, cfg)
      vim.lsp.enable(server)
      -- log.write("Enabled LSP: " .. server)
    else
      vim.notify("Failed to load LSP config for " .. server .. ": " .. cfg, vim.log.levels.ERROR)
    end
  end
end

-- load specific plugins
-- local log = require("utils.log")
--
-- local enabled_plugins = {
-- 	"lua_ls",
-- 	"pyright",
-- 	"clangd",
-- }
--
-- return function()
--   for _, server in ipairs(enabled_plugins) do
--     local ok, cfg = pcall(require, "configs.plugins.lsps.pluginlist." .. server)
--     if ok then
--       vim.lsp.config(server, cfg)
--       vim.lsp.enable(server)
--       -- log.write("Enabled LSP: " .. server)
--     else
--       vim.notify("Failed to load LSP config for " .. server .. ": " .. cfg, vim.log.levels.ERROR)
--     end
--   end
-- end

-- load every plugin
-- local log = require("utils.log")
--
--
-- return function()
--   local lspconfig_path = vim.fn.stdpath("config") .. "/lua/configs/plugins/lsps/pluginlist"
--
--   for _, file in ipairs(vim.fn.readdir(lspconfig_path)) do
--     if file:match("%.lua$") and file ~= "init.lua" then
--       local server = file:gsub("%.lua$", "")
--
--       local ok, cfg = pcall(require, "configs.plugins.lsps.pluginlist." .. server)
--       if ok then
--         -- Register LSP configuration
--         vim.lsp.config(server, cfg)
--
--         -- Enable server with its config
--         vim.lsp.enable(server)
--
-- 	log.write("Enabled LSP: " .. server)
--       else
--         vim.notify("Failed to load LSP config for " .. server .. ": " .. cfg, vim.log.levels.ERROR)
--       end
--     end
--   end
-- end
--
