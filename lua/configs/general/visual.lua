-- netrw file viewer (:Ex) hide ./
vim.g.netrw_hide = 1
vim.g.netrw_list_hide = "^./$"

-- line numbers on right and coloring of the one im on rn
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.cursorlineopt = "number"

vim.opt.tabstop = 4 -- visual width of tabs
vim.opt.shiftwidth = 4 -- indentation width
vim.opt.softtabstop = 4 -- spaces per Tab in insert mode
vim.opt.expandtab = true -- convert tabs to spaces
