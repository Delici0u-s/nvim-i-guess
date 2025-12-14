-- map helper
local kb = require("utils.keybinds")

-- remove highlighting
kb.map(
	"n",
	"<C-l>",
	[[ (&hls && v:hlsearch ? ':nohls' : ':set hls')."\n" <BAR> redraw<CR>]],
	{ silent = true, expr = true }
)

-- save on ctrl s
kb.map("n", "<C-S>", ":w<cr>", { silent = true })
kb.map("i", "<C-S>", ":w<cr>", { silent = true })

-- exit terminal insert mode
kb.map("t", "<C-X>", "<C-\\><C-n>", { silent = true })

-- open terminal in vertical split
kb.map("n", "<leader>vt", function()
	vim.cmd("vsplit")
	vim.cmd("terminal")
end, { desc = "Vertical terminal" })
