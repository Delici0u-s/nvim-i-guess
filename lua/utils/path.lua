-- Utility functions for LSP configuration

local M = {}

-- Accept buffer number or filename string, fallback to cwd
function M.normalize_path(input)
  if type(input) == "number" then
    input = vim.api.nvim_buf_get_name(input)
  end
  if input == nil or input == "" then
    return vim.loop.cwd()
  end
  return input
end

-- Factory to generate root_dir function given a list of project markers
function M.root_dir_factory(markers)
  return function(fname)
    local start_path = M.normalize_path(fname)
    local found = vim.fs.find(markers, { path = start_path })
    if found and found[1] then
      return vim.fs.dirname(found[1])
    end
    return vim.fs.dirname(start_path)
  end
end

return M

