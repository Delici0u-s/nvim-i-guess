-- Window cycling, netrw explorer and tab management.
local kb = require("utils.keybinds")

-- Cycle windows in one chord: <A-w> = <C-w>w, <A-q> = <C-w>W (q is left of w,
-- so "back"). <C-w>W needs Shift inside a two-key sequence, which is slow for
-- stepping back repeatedly. <cmd> keeps them working from a terminal split
-- without leaving terminal mode first. A count jumps to window N, like <C-w>w.
kb.map({ "n", "t" }, "<A-w>", function()
	vim.cmd((vim.v.count > 0 and vim.v.count or "") .. "wincmd w")
end, { desc = "Window: next" })
kb.map({ "n", "t" }, "<A-q>", function()
	vim.cmd((vim.v.count > 0 and vim.v.count or "") .. "wincmd W")
end, { desc = "Window: previous" })

-- <C-q> closes the window (:quit; 'confirm' asks about unsaved changes),
-- next to <C-x> (write and close). It replaces the built-in <C-q> (instant
-- Visual block), which moved to <A-v> in editor.lua.
kb.map("n", "<C-q>", "<cmd>quit<CR>", { desc = "Window: close" })

kb.map("n", "<C-h>x", "<cmd>Hex<CR>", { desc = "netrw: explore (hsplit)", silent = true })
kb.map("n", "<C-v>x", "<cmd>Vex<CR>", { desc = "netrw: explore (vsplit)", silent = true })
kb.map("n", "<C-e>x", "<cmd>Ex<CR>", { desc = "netrw: explore", silent = true })

kb.map("n", "<space>tn", "<cmd>tabnew<CR>", { desc = "Tab: new" })
kb.map("n", "<space>tc", "<cmd>tabclose<CR>", { desc = "Tab: close" })
kb.map("n", "<space>to", "<cmd>tabonly<CR>", { desc = "Tab: only" })
kb.map("n", "<space>tl", "<cmd>tabs<CR>", { desc = "Tab: list" })
kb.map("n", "<space>tm", ":tabmove ", { desc = "Tab: move" })
