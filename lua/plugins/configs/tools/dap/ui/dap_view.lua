-- igorlfs/nvim-dap-view: one tabbed panel (switch views with the winbar
-- letters) plus the program's console.
local M = {}

local function view()
	return require("dap-view")
end

function M.setup()
	view().setup({
		winbar = {
			sections = { "scopes", "watches", "threads", "breakpoints", "exceptions", "repl" },
			default_section = "scopes",
		},
		auto_toggle = true, -- open with a session, close when the last one ends
	})
end

function M.toggle()
	view().toggle()
end

function M.eval(expr)
	-- nil expr: dap-view takes the word or visual selection itself.
	view().hover(expr, true)
end

function M.watch(expr)
	view().add_expr(expr)
end

function M.frames()
	view().open()
	view().jump_to_view("threads")
end

function M.scopes()
	view().open()
	view().jump_to_view("scopes")
end

return M
