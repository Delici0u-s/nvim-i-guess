-- lua/config/init.lua
local config_dir = vim.fn.stdpath('config') .. '/lua/config'

-- Add both module files and module-init patterns to package.path
package.path = config_dir .. '/?.lua;' .. config_dir .. '/?/init.lua;' .. package.path

-- list modules (must match filenames exactly)
local Files = { 'conf_lazy', 'conf_tree_sitter' }  -- note fixed name: tree_sitter

for _, File in pairs(Files) do
  require(File)
end
