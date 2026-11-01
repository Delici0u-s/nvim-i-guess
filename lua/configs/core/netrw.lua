-- netrw file explorer.
--
-- netrw's display state (`netrw_list_hide`, `netrw_liststyle`, `netrw_hide`)
-- is GLOBAL, not buffer-local. Toggling mutates every netrw buffer at once,
-- and open buffers do not redraw on their own -- hence refresh() below.
--
-- The primary explorer is snacks (plugins/configs/ui/snacks.lua, <C-e>e).
-- netrw is kept for :Ex/:Hex/:Vex splits and scp:// remote browsing, which
-- snacks.explorer does not handle.

local M = {}

-- Patterns hidden when hiding is active. netrw wants a comma-joined
-- regex list; keep them here so the toggle has something to restore.
M.hidden = table.concat({
	[[^\./$]],
	[[^\..*$]],
	-- [[^\.\./$]],
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
-- netrw applies this string via setlocal to every explorer buffer, on setup
-- AND on each directory change. The default is "noma nomod nonu nobl nowrap
-- ro": its built-in "nonu" turns numbers off in netrw no matter what
-- autocmds do. Swapping in "nu" is netrw's own supported knob (netrw_bufsets
-- in :h netrw). relativenumber is omitted, so it inherits the global setting.
vim.g.netrw_bufsettings = "noma nomod nu nowrap ro nobl"

local ops = require("utils.netrw")

--- Redraw the current netrw buffer so a global change takes effect. Keeps
--- the tree's expanded folders, sort order and the entry under the cursor
--- (by path: toggling hidden files shifts line numbers).
local function refresh()
	ops.refresh()
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

-- Keys replaced in local netrw buffers -> utils/netrw.lua function.
M.ops = {
	["D"] = { fn = "delete", desc = "delete entry under cursor" },
	["d"] = { fn = "mkdir", desc = "new folder" },
	["%"] = { fn = "new_file", desc = "new file" },
	["R"] = { fn = "rename", desc = "rename / move entry" },
	["<C-l>"] = { fn = "refresh", desc = "refresh, keeping tree state" },
}

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
		map("<space>gh", M.toggle_hidden, "toggle hidden files")
		map("gl", M.cycle_liststyle, "cycle list style")
		map("<space>gl", M.cycle_liststyle, "cycle list style")
		map("gb", M.toggle_banner, "toggle banner")
		map("<space>gb", M.toggle_banner, "toggle banner")
		-- File operations that resolve the path under the cursor (netrw's own
		-- use a stale folder in tree view; see utils/netrw.lua). Marked files
		-- and remote buffers still go to netrw's original mapping.
		for lhs, op in pairs(M.ops) do
			local orig = vim.fn.maparg(lhs, "n", false, true)
			-- netrw remaps on every redraw; ours (a Lua callback) may still be there.
			if orig.callback then
				orig = vim.b[ev.buf].netrw_orig_maps and vim.b[ev.buf].netrw_orig_maps[lhs] or {}
			else
				local saved = vim.b[ev.buf].netrw_orig_maps or {}
				saved[lhs] = orig
				vim.b[ev.buf].netrw_orig_maps = saved
			end
			map(lhs, function()
				if ops.handles_current() then
					return ops[op.fn]()
				end
				if orig.rhs then
					-- maparg() leaves <SID> unexpanded; it only means something inside netrw.
					local rhs = orig.rhs:gsub("<SID>", ("<SNR>%d_"):format(orig.sid))
					local keys = vim.api.nvim_replace_termcodes(rhs, true, true, true)
					vim.api.nvim_feedkeys(keys, orig.noremap == 1 and "n" or "m", false)
				end
			end, op.desc)
		end

		map("q", "<cmd>bdelete<CR>", "close explorer")
		map("<space>q", "<cmd>bdelete<CR>", "close explorer")

		vim.bo[ev.buf].buflisted = false
		vim.bo[ev.buf].bufhidden = "wipe"
	end,
})

return M
