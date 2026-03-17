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
