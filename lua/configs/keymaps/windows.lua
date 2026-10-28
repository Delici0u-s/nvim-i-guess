-- netrw explorer and tab management.
local kb = require("utils.keybinds")

kb.map("n", "<C-h>x", "<cmd>Hex<CR>", { desc = "netrw: explore (hsplit)", silent = true })
kb.map("n", "<C-v>x", "<cmd>Vex<CR>", { desc = "netrw: explore (vsplit)", silent = true })
kb.map("n", "<C-e>x", "<cmd>Ex<CR>", { desc = "netrw: explore", silent = true })

kb.map("n", "<space>tn", "<cmd>tabnew<CR>", { desc = "Tab: new" })
kb.map("n", "<space>tc", "<cmd>tabclose<CR>", { desc = "Tab: close" })
kb.map("n", "<space>to", "<cmd>tabonly<CR>", { desc = "Tab: only" })
kb.map("n", "<space>tl", "<cmd>tabs<CR>", { desc = "Tab: list" })
kb.map("n", "<space>tm", ":tabmove ", { desc = "Tab: move" })
