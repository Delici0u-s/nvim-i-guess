-- netrw file explorer.
--
-- netrw's display state (`netrw_list_hide`, `netrw_liststyle`, `netrw_hide`)
-- is GLOBAL, not buffer-local. Toggling mutates every netrw buffer at once,
-- and open buffers do not redraw on their own -- hence refresh() below.
--
-- The primary explorer is snacks (configs/plugins/ui/snacks.lua, <C-e>e).
-- netrw is kept for :Ex/:Hex/:Vex splits and scp:// remote browsing, which
-- snacks.explorer does not handle.

local M = {}

-- Patterns hidden when hiding is active. netrw wants a comma-joined
-- regex list; keep them here so the toggle has something to restore.
M.hidden = table.concat({
	[[^\./$]],
	[[^\.\./$]],
	[[^__pycache__/$]],
	[[^\.git/$]],
	[[^node_modules/$]],
}, ",")

-- 0 = thin, 1 = long, 2 = wide, 3 = tree
M.liststyle = 3

vim.g.netrw_banner = 0
vim.g.netrw_liststyle = M.liststyle
vim.g.netrw_list_hide = M.hidden
vim.g.netrw_hide = 1 -- 0 = show all, 1 = hide matches, 2 = show only matches
vim.g.netrw_sizestyle = "H" -- human-readable sizes
vim.g.netrw_localcopydircmd = "cp -r"

--- Redraw the current netrw buffer so a global change takes effect.
local function refresh()
	if vim.bo.filetype ~= "netrw" then
		return
	end
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Plug>NetrwRefresh", true, false, true), "n", false)
end

--- Toggle whether hidden files are filtered out.
function M.toggle_hidden()
	vim.g.netrw_hide = vim.g.netrw_hide == 1 and 0 or 1
	refresh()
	vim.notify("netrw: hidden files " .. (vim.g.netrw_hide == 1 and "hidden" or "shown"), vim.log.levels.INFO)
end

--- Cycle thin -> long -> wide -> tree.
function M.cycle_liststyle()
	vim.g.netrw_liststyle = (vim.g.netrw_liststyle + 1) % 4
	refresh()
	local names = { [0] = "thin", "long", "wide", "tree" }
	vim.notify("netrw: " .. names[vim.g.netrw_liststyle], vim.log.levels.INFO)
end

--- Toggle the banner.
function M.toggle_banner()
	vim.g.netrw_banner = vim.g.netrw_banner == 1 and 0 or 1
	refresh()
end

-- Buffer-local maps. Must be set on FileType: netrw installs its own maps when
-- the buffer is created, so anything global gets shadowed.
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("netrw_maps", { clear = true }),
	pattern = "netrw",
	callback = function(ev)
		local function map(lhs, rhs, desc)
			vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, silent = true, desc = "netrw: " .. desc })
		end

		map("gh", M.toggle_hidden, "toggle hidden files")
		map("gl", M.cycle_liststyle, "cycle list style")
		map("gb", M.toggle_banner, "toggle banner")
		map("q", "<cmd>bdelete<CR>", "close explorer")

		vim.bo[ev.buf].buflisted = false
		vim.bo[ev.buf].bufhidden = "wipe"
	end,
})

return M
