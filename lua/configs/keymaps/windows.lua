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

-- <C-q> closes the window, next to <C-x> (write and close). It replaces the
-- built-in <C-q> (instant Visual block), which moved to <A-v> in editor.lua.
--
-- When closing would lose changes, Neovim's 'confirm' dialog only takes its own
-- letters, so this asks instead: a second <C-q> closes without saving.
local function close_window()
	local confirm = vim.o.confirm
	vim.o.confirm = false -- fail with an error instead of showing the dialog
	local ok, err = pcall(vim.cmd.quit)
	vim.o.confirm = confirm
	if ok then
		return
	end
	-- One line that fits v:echospace (the width left next to ruler/showcmd):
	-- anything taller or wider makes Neovim show "Press ENTER", which hides the
	-- choices. Longest variant that fits wins; the last one is cut to fit.
	local reason = (tostring(err):match("E%d+: (.*)") or tostring(err)):gsub("%s*%(add ! to override%)", "")
	local options = {
		"<C-q> again: close without saving · y: save and close · other key: cancel",
		"<C-q>: discard · y: save · other: cancel",
	}
	local line
	for _, opt in ipairs(options) do
		for _, text in ipairs({ reason .. " · " .. opt, opt }) do
			if not line and vim.fn.strdisplaywidth(text) <= vim.v.echospace then
				line = text
			end
		end
	end
	line = line or vim.fn.strcharpart(options[#options], 0, vim.v.echospace)
	vim.api.nvim_echo({ { line, "Question" } }, false, {})
	local key = vim.fn.getcharstr()
	vim.cmd.redraw()
	vim.api.nvim_echo({ { "" } }, false, {})
	if key == vim.keycode("<C-q>") or key == "n" then
		vim.cmd("quit!")
	elseif key == "y" then
		local saved, save_err = pcall(vim.cmd, "write | quit")
		if not saved then
			vim.notify(tostring(save_err):match("E%d+: .*") or tostring(save_err), vim.log.levels.ERROR)
		end
	end
end
kb.map("n", "<C-q>", close_window, { desc = "Window: close (<C-q><C-q>: without saving)" })

kb.map("n", "<C-h>x", "<cmd>Hex<CR>", { desc = "netrw: explore (hsplit)", silent = true })
kb.map("n", "<C-v>x", "<cmd>Vex<CR>", { desc = "netrw: explore (vsplit)", silent = true })
kb.map("n", "<C-e>x", "<cmd>Ex<CR>", { desc = "netrw: explore", silent = true })

kb.map("n", "<space>tn", "<cmd>tabnew<CR>", { desc = "Tab: new" })
kb.map("n", "<space>tc", "<cmd>tabclose<CR>", { desc = "Tab: close" })
kb.map("n", "<space>to", "<cmd>tabonly<CR>", { desc = "Tab: only" })
kb.map("n", "<space>tl", "<cmd>tabs<CR>", { desc = "Tab: list" })
kb.map("n", "<space>tm", ":tabmove ", { desc = "Tab: move" })
