-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

-- mapleader/maplocalleader are set in init.lua, before this file is reached.

require("lazy").setup({
	spec = {
		{ import = "plugins/lazy" },
	},
	install = { colorscheme = { "habamax" } },
	checker = { enabled = false },
	change_detection = {
		enabled = true,
		notify = false, -- don't interrupt on every config save
	},
	performance = {
		rtp = {
			-- Disable builtin plugins that are unused here. netrw is kept:
			-- visual.lua configures it and :Ex/:Hex/:Vex are mapped.
			disabled_plugins = {
				"gzip",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
				"rplugin",
			},
		},
	},
})
