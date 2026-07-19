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
