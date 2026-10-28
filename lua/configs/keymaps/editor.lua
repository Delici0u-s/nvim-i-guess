-- Core editing keymaps: search, saving, macros.
local kb = require("utils.keybinds")

-- <C-l> toggles search highlighting and redraws.
kb.map(
	"n",
	"<C-l>",
	[[ (&hls && v:hlsearch ? ':nohls' : ':set hls')."\n" <BAR> redraw<CR>]],
	{ silent = true, expr = true, desc = "Editor: toggle search highlight" }
)

-- <C-S> saves. In insert mode it round-trips out and back so the cursor
-- position and insert state are preserved.
kb.map("n", "<C-S>", ":w<cr>@s", { silent = true, desc = "Editor: save" })
kb.map("i", "<C-S>", function()
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
	vim.cmd("w")
	vim.api.nvim_feedkeys("i", "n", true)
end, { silent = true, desc = "Editor: save (stay in insert)" })

-- <C-a> then a register letter runs that macro, without needing @.
kb.map("n", "<C-a>", function()
	vim.api.nvim_echo({ { "Press macro register:", "Normal" } }, false, {})
	local reg = vim.fn.nr2char(vim.fn.getchar())
	if reg ~= "" then
		vim.api.nvim_feedkeys("@" .. reg, "n", true)
	end
end, { silent = true, desc = "Editor: run macro from register" })
