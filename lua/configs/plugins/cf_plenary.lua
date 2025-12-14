local kb = require("utils.keybinds")

local builtin = require('telescope.builtin')

require('telescope').setup{
}

kb.map('n', '<C-t>f', builtin.find_files, { desc = 'Telescope find files' })
kb.map('n', '<C-t>g', builtin.live_grep, { desc = 'Telescope live grep' })
kb.map('n', '<C-t>b', builtin.buffers, { desc = 'Telescope buffers' })
kb.map('n', '<C-t>h', builtin.help_tags, { desc = 'Telescope help tags' })
kb.map('n', '<C-t>m', builtin.man_pages, { desc = 'Telescope man pages' })


