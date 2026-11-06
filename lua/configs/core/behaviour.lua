-- Correct undo setup
local undo_path = vim.fn.expand("~/.local/share/nvim/undo") -- expand ~ here
vim.fn.mkdir(undo_path, "p") -- create directory if it doesn't exist
vim.opt.undofile = true
vim.opt.undodir = undo_path .. "//"
vim.opt.undolevels = 10000
vim.opt.undoreload = 10000

vim.api.nvim_create_autocmd({ "VimLeavePre" }, {
	group = vim.api.nvim_create_augroup("fuck_shada_temp", { clear = true }),
	pattern = { "*" },
	callback = function()
		local status = 0
		for _, f in ipairs(vim.fn.globpath(vim.fn.stdpath("data") .. "/shada", "*tmp*", false, true)) do
			if vim.tbl_isempty(vim.fn.readfile(f)) then
				status = status + vim.fn.delete(f)
			end
		end
		if status ~= 0 then
			vim.notify("Could not delete empty temporary ShaDa files.", vim.log.levels.ERROR)
			vim.fn.getchar()
		end
	end,
	desc = "Delete empty temp ShaDa files",
})

-- 'autoread' only reloads when Neovim checks the file; trigger that check on
-- focus/buffer switch/idle so edits made outside Neovim show up. Unmodified
-- buffers reload silently; you are only asked when the buffer has unsaved
-- edits AND the file changed on disk.
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
	group = vim.api.nvim_create_augroup("reload_changed_files", { clear = true }),
	callback = function()
		-- :checktime errors in the command-line window (E11).
		if vim.fn.getcmdwintype() == "" then
			vim.cmd.checktime()
		end
	end,
	desc = "Reload buffers whose files changed on disk",
})
