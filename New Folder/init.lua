-- print logfile location
local log = require("utils.log")
print("Logfile path: " .. log._log_path)
log.write("New Session =_=!!!")

vim.o.shell = "zsh"
vim.o.shellcmdflag = "-ic"
vim.o.shellxquote = ""

vim.g.mlang_config = {
	enable_diagnostics = true,
	allowed_severities = { 1, 2 }, -- show Errors + Warnings only
	ignore_patterns = { "Undefined function", "not found", "unexpected token" },
}

-- loads custom configs, loads like everything lmao
require("configs")

-- print successfull loading of "packages" or whatever the fuck dis called
log.write(vim.inspect(package.loaded["configs.plugins.cf_lspconfig"]))
log.write(vim.inspect(package.loaded["configs.general.keybinds"]))

-- local bdvt_api = require("better-diagnostic-virtual-text.api")
-- vim.api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
--     callback = function()
--         -- local l = ""
--         for _, buf in ipairs(vim.api.nvim_list_bufs()) do
--             -- l = l .. buf .. "\n"
--             vim.api.nvim_exec_autocmds('BufWritePost', { buffer = buf })
--         end
--         -- print(l)
--     end,
-- })

-- vim.api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
--     callback = function()
--         for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
--             local wins = vim.fn.win_findbuf(bufnr)
--             for _, win in ipairs(wins) do
--                 vim.api.nvim_win_call(win, function()
--                     require("better-diagnostic-virtual-text.api").clear_extmark_cache(bufnr)
--                     vim.api.nvim_exec_autocmds("DiagnosticChanged", {
--                         buffer = bufnr,
--                         data = { diagnostics = vim.diagnostic.get(bufnr) }
--                     })
--                 end)
--             end
--         end
--     end,
-- })
