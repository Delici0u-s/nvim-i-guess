local M = {}

-- defaults
M._log_path = vim.fn.stdpath("cache") .. "\\nvimdebug.log"
M._this_is_a_log_table = true
M._fh = nil -- lazy initialized

-- Helper: return the source path of the caller of the write function.
-- level is relative to the function that calls debug.getinfo.
-- When used from M.write(), level = 2 yields the caller of M.write().
function M.script_path(level)
  local info = debug.getinfo(level or 3, "S")
  if not info or not info.source then
    return "unknown"
  end
  local s = info.source
  -- strip leading '@' which debug uses for file sources
  if s:sub(1,1) == "@" then
    return s:sub(2)
  end
  return s
end

-- Write to log. Supports both:
--   log:write("a", "b")
--   log.write("a", "b")
function M.write(self_or_first, ...)
  local is_method = type(self_or_first) == "table" and self_or_first._this_is_a_log_table
  local instance = M
  local values = {}

  if is_method then
    instance = self_or_first
    for i = 1, select("#", ...) do
      values[i] = select(i, ...)
    end
  else
    -- called as function: first arg is actually the first value to log
    values[1] = self_or_first
    for i = 1, select("#", ...) do
      values[#values + 1] = select(i, ...)
    end
  end

  -- ensure file handle
  if not instance._fh then
    local ok, fh_or_err = pcall(io.open, instance._log_path, "a")
    if not ok or not fh_or_err then
      -- if opening fails, notify and return without erroring the caller
      if vim and vim.notify then
        vim.notify("Failed to open log file: " .. tostring(fh_or_err), vim.log.levels.ERROR)
      end
      return
    end
    instance._fh = fh_or_err
  end

  local buf = {}
  for i = 1, #values do
    table.insert(buf, vim.inspect(values[i]))
  end

  -- get caller source (caller of M.write is at stack level 2)
  local info = debug.getinfo(2, "S")
  local src = "unknown"
  if info and info.source then
    local s = info.source
    if s:sub(1,1) == "@" then
      src = s:sub(2)
    else
      src = s
    end
  end

  local ok, err = pcall(function()
    instance._fh:write(
      os.date("%Y:%m:%d %H.%M.%S")
      .. " "
      .. src
      .. "\n"
      .. table.concat(buf, "\n")
      .. "\n\n"
    )
    instance._fh:flush()
  end)
  if not ok then
    if vim and vim.notify then
      vim.notify("Failed to write to log: " .. tostring(err), vim.log.levels.ERROR)
    end
  end
end

-- Optional: close file handle (call on exit if desired)
function M.close()
  if M._fh then
    pcall(function() M._fh:close() end)
    M._fh = nil
  end
end

return M

