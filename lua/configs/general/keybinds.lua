-- map helper
local kb = require("utils.keybinds")

-- more keybinds in cf_cmp.lua

kb.map(
	"n",
	"<C-l>",
	[[ (&hls && v:hlsearch ? ':nohls' : ':set hls')."\n" <BAR> redraw<CR>]],
	{ silent = true, expr = true }
)

kb.map("n", "<C-S>", ":w<cr>", { silent = true })
kb.map("i", "<C-S>", ":w<cr>", { silent = true })
-- exit terminal insert mode
kb.map("t", "<C-X>", "<C-\\><C-n>", { silent = true })
