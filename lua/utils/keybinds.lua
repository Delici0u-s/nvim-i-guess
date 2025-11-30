local M = {}

function M.map(mode, lhs, rhs, opts)
  local options = { noremap = true }
  if opts then
    options = vim.tbl_extend("force", options, opts)
  end

  -- If rhs is a function (or mode is a table), use the newer API that accepts functions/tables.
  if type(rhs) == "function" or type(mode) == "table" then
    -- vim.keymap.set accepts mode as string or table and rhs as function or string.
    vim.keymap.set(mode, lhs, rhs, options)
    return
  end

  -- otherwise use the classical API (string rhs)
  vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

return M
