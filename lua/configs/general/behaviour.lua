-- Correct undo setup
local undo_path = vim.fn.expand("~/.local/share/nvim/undo") -- expand ~ here
vim.fn.mkdir(undo_path, "p") -- create directory if it doesn't exist
vim.opt.undofile = true
vim.opt.undodir = undo_path .. "//"
vim.opt.undolevels = 10000
vim.opt.undoreload = 10000
