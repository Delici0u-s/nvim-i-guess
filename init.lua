-- Leader must be set before lazy.nvim loads any spec, and before any
-- module defines a <leader> mapping.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Interactive zsh so `:!` and :terminal inherit aliases/functions.
vim.o.shell = "zsh"
vim.o.shellcmdflag = "-ic"
vim.o.shellxquote = ""

require("configs")

-- Leader must be set before lazy.nvim loads any spec, and before any
-- module defines a <leader> mapping.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Interactive zsh so `:!` and :terminal inherit aliases/functions.
vim.o.shell = "zsh"
vim.o.shellcmdflag = "-ic"
vim.o.shellxquote = ""

require("configs")
