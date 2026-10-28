-- rcarriga/nvim-dap-ui: IDE-style panes that open with a session.
local M = {}

local function dapui()
	return require("dapui")
end

function M.setup()
	local dap = require("dap")
	dapui().setup({
		-- Breakpoints have signs and <leader>db; console and REPL share the
		-- bottom so the code keeps most of the screen. Sizes are fractions of
		-- the editor, so they follow the window size.
		layouts = {
			{
				position = "left",
				size = 0.25,
				elements = {
					{ id = "scopes", size = 0.5 },
					{ id = "watches", size = 0.25 },
					{ id = "stacks", size = 0.25 },
				},
			},
			{
				position = "bottom",
				size = 0.25,
				elements = { "console", "repl" },
			},
		},
	})

	dap.listeners.before.attach.dap_ui = dapui().open
	dap.listeners.before.launch.dap_ui = dapui().open
	dap.listeners.before.event_terminated.dap_ui = dapui().close
	dap.listeners.before.event_exited.dap_ui = dapui().close
end

function M.toggle()
	dapui().toggle()
end

function M.eval(expr)
	dapui().eval(expr, { enter = true })
end

function M.watch(expr)
	dapui().elements.watches.add(expr)
end

function M.frames()
	dapui().float_element("stacks", { enter = true })
end

function M.scopes()
	dapui().float_element("scopes", { enter = true })
end

return M
