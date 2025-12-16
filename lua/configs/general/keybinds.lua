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
kb.map("i", "<C-S>", function()
	-- Exit insert mode
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
	-- Save the file
	vim.cmd("w")
	-- Re-enter insert mode
	vim.api.nvim_feedkeys("i", "n", true)
end, { silent = true })

-- exit terminal insert mode
kb.map("t", "<C-X>", "<C-\\><C-n>", { silent = true })

-- open terminal in vertical split
kb.map("n", "vt", function()
	vim.cmd("vsplit")
	vim.cmd("terminal")
end, { desc = "Vertical terminal" })

-- open terminal in vertical split
kb.map("n", "vt", function()
	vim.cmd("vsplit")
	vim.cmd("terminal")
end, { desc = "Vertical terminal" })

-- open terminal in horizontal split
kb.map("n", "ht", function()
	vim.cmd("split") -- corrected command
	vim.cmd("terminal")
end, { desc = "Horizontal terminal" })

-- todo implement hotkey hook
