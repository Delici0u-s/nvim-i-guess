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

--- File buffers whose changes closing this window would lose (empty: none).
--- Decided up front: letting :quit fail and catching it still makes Neovim
--- show "Press ENTER", which hid the question.
local function would_lose()
	if vim.fn.winnr("$") == 1 and vim.fn.tabpagenr("$") == 1 then
		-- Last window: closing exits Neovim, so every modified file counts.
		return vim.tbl_filter(function(info)
			local bt = vim.bo[info.bufnr].buftype
			return bt == "" or bt == "acwrite"
		end, vim.fn.getbufinfo({ bufmodified = 1 }))
	end
	-- Otherwise the buffer is only hidden, unless it can't be.
	local buf = vim.api.nvim_get_current_buf()
	local hides = vim.o.hidden or vim.bo.bufhidden == "hide"
	if vim.bo.modified and not hides and #vim.fn.win_findbuf(buf) == 1 then
		return vim.fn.getbufinfo(buf)
	end
	return {}
end

--- One line that fits v:echospace (the width left next to ruler/showcmd):
--- anything taller or wider also triggers "Press ENTER". The longest variant
--- that fits wins; the last one is cut to fit as a last resort.
local function question(lost)
	local what = #lost == 1
			and ((lost[1].name ~= "" and vim.fn.fnamemodify(lost[1].name, ":t") or "[No Name]") .. " has unsaved changes")
		or (#lost .. " files have unsaved changes")
	local options = {
		"<C-q> again: close without saving · y: save and close · other key: cancel",
		"<C-q>: discard · y: save · other: cancel",
	}
	for _, opt in ipairs(options) do
		for _, text in ipairs({ what .. " · " .. opt, opt }) do
			if vim.fn.strdisplaywidth(text) <= vim.v.echospace then
				return text
			end
		end
	end
	return vim.fn.strcharpart(options[#options], 0, vim.v.echospace)
end

local function close_window()
	local lost = would_lose()
	if #lost == 0 then
		return vim.cmd.quit()
	end
	vim.api.nvim_echo({ { question(lost), "Question" } }, false, {})
	local key = vim.fn.getcharstr()
	vim.api.nvim_echo({ { "" } }, false, {})
	local last = vim.fn.winnr("$") == 1 and vim.fn.tabpagenr("$") == 1
	local ok, err = true, nil
	if key == vim.keycode("<C-q>") or key == "n" then
		-- The question named every file that loses changes, so discard them all.
		ok, err = pcall(vim.cmd, last and "qall!" or "quit!")
	elseif key == "y" then
		ok, err = pcall(vim.cmd, last and "wall | quit" or "write | quit")
	end
	if not ok then
		vim.notify(tostring(err):match("E%d+: .*") or tostring(err), vim.log.levels.ERROR)
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
