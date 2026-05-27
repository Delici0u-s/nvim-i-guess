vim.api.nvim_create_user_command("themeSwitch", function()
	local theme = require("configs.theme")
	local next_mode = (vim.g.theme_mode == "dark") and "light" or "dark"
	theme.apply_mode(next_mode)
	vim.notify("Theme → " .. next_mode .. "  (session only)", vim.log.levels.INFO)
end, { desc = "Toggle dark/light theme for this session" })

vim.api.nvim_create_user_command("themeSwitchPermanent", function()
	local theme = require("configs.theme")
	local next_mode = (vim.g.theme_mode == "dark") and "light" or "dark"

	theme.apply_mode(next_mode)

	-- Patch the M.mode line in init.lua
	local init_path = vim.fn.stdpath("config") .. "/lua/configs/theme/init.lua"
	local lines = vim.fn.readfile(init_path)
	for i, line in ipairs(lines) do
		if line:match("^M%.mode%s*=") then
			lines[i] = 'M.mode = "' .. next_mode .. '"'
			break
		end
	end
	vim.fn.writefile(lines, init_path)

	vim.notify("Theme → " .. next_mode .. "  (permanent)", vim.log.levels.INFO)
end, { desc = "Toggle dark/light theme and persist to config" })
