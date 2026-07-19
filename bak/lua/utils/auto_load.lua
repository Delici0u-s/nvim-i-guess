-- utils/auto_load.lua
local M = {}

-- Get the folder of the *caller* of load_files_in_dir().
-- We prefer stack level 3 (caller -> load_files_in_dir -> current_folder).
-- If that fails, fall back to the current file (level 1).
local function current_folder()
  local info = debug.getinfo(3, "S") or debug.getinfo(1, "S")
  if not info or not info.source then
    return vim.fn.getcwd()
  end
  local src = info.source
  if src:sub(1,1) == "@" then
    src = src:sub(2)
  end
  -- return absolute directory
  local abs = vim.fn.fnamemodify(src, ":p")
  return vim.fn.fnamemodify(abs, ":h")
end

-- Convert a filesystem path to a Lua module prefix.
-- Example: ".../nvim/lua/configs" -> "configs"
local function folder_to_module(path)
  -- normalize to forward slashes (works on Windows too)
  local p = path:gsub("\\", "/")
  local module = p:match(".*/lua/(.+)")
  if not module then
    -- fallback: try to use the final folder name
    module = vim.fn.fnamemodify(p, ":t")
  end
  -- replace slashes with dots
  module = module:gsub("/", ".")
  return module
end

-- Load all .lua files in the caller's folder (skip init.lua)
function M.load_files_in_dir()
  local path = current_folder()
  local mod_prefix = folder_to_module(path)
  -- glob all .lua files in that folder
  local pattern = path .. "/*.lua"
  for _, file in ipairs(vim.fn.glob(pattern, false, true)) do
    local name = vim.fn.fnamemodify(file, ":t:r")
    if name ~= "init" then
      local modname = mod_prefix .. "." .. name
      local ok, err = pcall(require, modname)
      if not ok then
        vim.notify(("Failed to require '%s': %s"):format(modname, tostring(err)), vim.log.levels.WARN)
      end
    end
  end
end

-- Optionally: load subfolders by requiring their init.lua
function M.load_folders_in_dir()
  local path = current_folder()
  local mod_prefix = folder_to_module(path)
  for _, entry in ipairs(vim.fn.readdir(path)) do
    local full = path .. "/" .. entry
    if vim.fn.isdirectory(full) == 1 then
      local modname = mod_prefix .. "." .. entry
      local ok, err = pcall(require, modname)
      if not ok then
        vim.notify(("Failed to require folder module '%s': %s"):format(modname, tostring(err)), vim.log.levels.WARN)
      end
    end
  end
end

-- convenience: load a given list of modules (relative to caller dir)
function M.load_list(list)
  assert(type(list) == "table", "load_list expects a table")
  local path = current_folder()
  local mod_prefix = folder_to_module(path)
  for _, name in ipairs(list) do
    local ok, err = pcall(require, mod_prefix .. "." .. name)
    if not ok then
      vim.notify(("Failed to require '%s.%s': %s"):format(mod_prefix, name, tostring(err)), vim.log.levels.WARN)
    end
  end
end

return M

