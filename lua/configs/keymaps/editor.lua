-- Core editing keymaps: search, saving, macros.
local kb = require("utils.keybinds")

-- <C-l> toggles search highlighting and redraws.
kb.map(
	"n",
	"<C-l>",
	[[ (&hls && v:hlsearch ? ':nohls' : ':set hls')."\n" <BAR> redraw<CR>]],
	{ silent = true, expr = true, desc = "Editor: toggle search highlight" }
)

-- <C-S> saves, then runs the project command if run-on-save is on
-- (utils/runner.lua, <leader>rss), then macro @s. In insert mode it
-- round-trips out and back so the cursor position and insert state are kept.
kb.map("n", "<C-S>", function()
	vim.cmd.write()
	require("utils.runner").on_save()
	vim.api.nvim_feedkeys("@s", "n", false)
end, { silent = true, desc = "Editor: save (+ run on save, @s)" })
kb.map("i", "<C-S>", function()
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
	vim.cmd("w")
	require("utils.runner").on_save()
	vim.api.nvim_feedkeys("i", "n", true)
end, { silent = true, desc = "Editor: save (stay in insert, + run on save)" })

-- Visual block without a wait. <C-v> is a mapping prefix here (<C-v>x), so the
-- bare <C-v> only starts Visual block after 'timeoutlen'; the built-in instant
-- alternative <C-q> closes windows instead (windows.lua).
kb.map("n", "<A-v>", "<C-v>", { desc = "Editor: Visual block mode" })

-- <C-a> then a register letter runs that macro, without needing @.
kb.map("n", "<C-a>", function()
	vim.api.nvim_echo({ { "Press macro register:", "Normal" } }, false, {})
	local reg = vim.fn.nr2char(vim.fn.getchar())
	if reg ~= "" then
		vim.api.nvim_feedkeys("@" .. reg, "n", true)
	end
end, { silent = true, desc = "Editor: run macro from register" })
