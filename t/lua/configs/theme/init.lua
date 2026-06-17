local M = {}

-- ── Configuration ─────────────────────────────────────────────────────────────
M.mode = "dark"
M.dark_theme = "bold"
-- M.light_theme = "solarflare-light"
M.light_theme = "bold-light"
-- ──────────────────────────────────────────────────────────────────────────────

local rainglow = vim.fn.stdpath("config") .. "/lua/configs/theme/themes/rainglow/"

function M.apply(theme_name)
	vim.cmd("source " .. rainglow .. theme_name .. ".vim")
end

function M.apply_mode(mode)
	local ibl_ok, ibl = pcall(require, "ibl")
	if mode == "light" then
		if ibl_ok then
			ibl.setup({ enabled = false })
		end
		M.apply(M.light_theme)
	else
		if ibl_ok then
			ibl.setup({ enabled = true })
		end
		M.apply(M.dark_theme)
	end
	vim.g.theme_mode = mode
end

-- Apply on startup
M.apply_mode(M.mode)

return M
