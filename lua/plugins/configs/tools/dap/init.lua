-- nvim-dap setup. Loaded by the nvim-dap spec on the first debugger key.
--
--   settings.lua -- which UI, which adapters, terminal; the knobs live there
--   keymaps.lua  -- every debugger key (also the spec's lazy `keys`)
--   launch.lua   -- program picker, argument prompt, Python venv detection
--   ui/          -- UI backends behind one interface (ui/init.lua)
--
-- Launch configurations come from mason-nvim-dap's defaults for each adapter
-- (improved by launch.lua) and from a project's .vscode/launch.json, which
-- nvim-dap reads by itself.

-- Sign glyph and the theme group its colour is linked to.
local signs = {
	DapBreakpoint = { text = "●", link = "DiagnosticError" },
	DapBreakpointCondition = { text = "◆", link = "DiagnosticWarn" },
	DapLogPoint = { text = "◉", link = "DiagnosticInfo" },
	DapBreakpointRejected = { text = "○", link = "DiagnosticHint" },
	DapStopped = { text = "▶", link = "DiagnosticOk", linehl = "DapStoppedLine" },
}

local function set_highlights()
	for name, sign in pairs(signs) do
		vim.api.nvim_set_hl(0, name, { link = sign.link, default = true })
	end
	vim.api.nvim_set_hl(0, "DapStoppedLine", { link = "Visual", default = true })
end

return function()
	local dap = require("dap")
	local settings = require("plugins.configs.tools.dap.settings")
	local launch = require("plugins.configs.tools.dap.launch")

	require("nvim-dap-virtual-text").setup({})

	-- Registers an installed adapter and its default configurations. Only
	-- adapters listed in settings, so an old install left in mason doesn't add
	-- a second set of configurations for the same filetypes.
	local function register(config, tweak)
		if not vim.tbl_contains(settings.adapters, config.name) then
			return
		end
		config.configurations = launch.with_args_variants(vim.tbl_map(function(c)
			c = launch.improve(c)
			return tweak and tweak(c) or c
		end, config.configurations or {}))
		require("mason-nvim-dap").default_setup(config)
	end

	require("mason-nvim-dap").setup({
		ensure_installed = settings.adapters,
		automatic_installation = true,
		handlers = {
			register,
			python = function(config)
				register(config, function(c)
					c.pythonPath = launch.python_path
					return c
				end)
			end,
		},
	})

	dap.defaults.fallback.external_terminal = settings.external_terminal

	-- Signs. Rainglow themes run `highlight clear`, which drops these groups,
	-- so they are re-linked on every colourscheme change.
	set_highlights()
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("dap_highlights", { clear = true }),
		callback = set_highlights,
	})
	for name, sign in pairs(signs) do
		vim.fn.sign_define(name, { text = sign.text, texthl = name, linehl = sign.linehl, numhl = "" })
	end

	require("plugins.configs.tools.dap.ui").setup()
end
