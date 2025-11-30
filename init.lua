-- print logfile location
local log = require("utils.log")
print("Logfile path: " .. log._log_path)
log.write('New Session!!!')

-- loads custom configs, loads like everything lmao
require("configs")


-- print successfull loading of "packages" or whatever the fuck dis called
log.write(vim.inspect(package.loaded["configs.plugins.cf_lspconfig"]))
log.write(vim.inspect(package.loaded["configs.general.keybinds"]))

vim.o.shell = "zsh"
vim.o.shellcmdflag = "-ic"
vim.o.shellxquote = ""


