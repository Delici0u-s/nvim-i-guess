-- nvim-dap's built-in widgets: no extra plugin. Also the fallback for actions
-- the selected UI doesn't implement (see ui/init.lua).
local M = {}

local function widgets()
	return require("dap.ui.widgets")
end

local sidebar -- created on first toggle, then reused

function M.toggle()
	sidebar = sidebar or widgets().sidebar(widgets().scopes, {}, "vsplit")
	sidebar.toggle()
end

function M.eval(expr)
	widgets().hover(expr or require("plugins.configs.tools.dap.ui").expression())
end

function M.frames()
	widgets().centered_float(widgets().frames)
end

function M.scopes()
	widgets().centered_float(widgets().scopes)
end

return M
