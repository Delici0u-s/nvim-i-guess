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
	-- Close when the last session is gone, however it ended. The terminated /
	-- exited events dap-ui's README hooks aren't always sent: codelldb answers
	-- <leader>dq (terminate) with a bare disconnect, so the UI stayed open.
	dap.listeners.on_session.dap_ui = function(_, new)
		if new == nil then
			M.close()
		end
	end
end

--- Close the UI. If the cursor is in one of its windows, move it to a code
--- window first, so it doesn't end up in whatever window happens to be left.
function M.close()
	local ft = vim.bo.filetype
	if ft:find("^dapui_") or ft == "dap-repl" then
		for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
			local buf = vim.api.nvim_win_get_buf(win)
			if vim.bo[buf].buftype == "" and not vim.bo[buf].filetype:find("^dapui_") then
				vim.api.nvim_set_current_win(win)
				break
			end
		end
	end
	dapui().close()
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
