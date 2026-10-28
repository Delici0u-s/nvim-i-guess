-- Debugger UI front-end. Keymaps call these functions; the backend named in
-- tools/dap/settings.lua does the work. A backend may leave an action out,
-- in which case the built-in "widgets" backend handles it.
--
-- Backend interface (every field optional):
--   setup()          -- once, when nvim-dap loads; register auto open/close here
--   toggle()         -- show/hide the UI
--   eval(expr?)      -- evaluate expr, or the word/selection under the cursor
--   watch(expr)      -- add a watch expression
--   frames()         -- show the call stack
--   scopes()         -- show variables in scope

local settings = require("plugins.configs.tools.dap.settings")

local backends = {
	["dap-ui"] = "plugins.configs.tools.dap.ui.dap_ui",
	["dap-view"] = "plugins.configs.tools.dap.ui.dap_view",
	widgets = "plugins.configs.tools.dap.ui.widgets",
}

local M = {}

local function backend()
	local module = backends[settings.ui]
	if not module then
		vim.notify(
			("Debug: unknown ui %q in tools/dap/settings.lua, using widgets"):format(tostring(settings.ui)),
			vim.log.levels.WARN
		)
		module = backends.widgets
	end
	return require(module)
end

local function action(name)
	return function(...)
		local impl = backend()[name] or require(backends.widgets)[name]
		if impl then
			return impl(...)
		end
		vim.notify(("Debug: %s is not supported by the %s UI"):format(name, settings.ui), vim.log.levels.INFO)
	end
end

--- Visual selection, or the expression under the cursor.
function M.expression()
	local mode = vim.fn.mode()
	if mode == "v" or mode == "V" then
		local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode })
		return table.concat(lines, "\n")
	end
	return vim.fn.expand("<cexpr>")
end

M.setup = action("setup")
M.toggle = action("toggle")
M.eval = action("eval")
M.watch = action("watch")
M.frames = action("frames")
M.scopes = action("scopes")

return M
