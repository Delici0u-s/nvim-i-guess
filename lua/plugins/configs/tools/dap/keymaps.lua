-- Debugger keymaps, as a lazy.nvim `keys` list: the nvim-dap spec uses this
-- table directly, so each key both loads nvim-dap and is mapped by lazy. Add a
-- key here and nowhere else.
--
-- F-keys follow the VS Code / Visual Studio layout; <leader>d mirrors them
-- with mnemonics and adds the rest.

local function dap()
	return require("dap")
end

local function ui()
	return require("plugins.configs.tools.dap.ui")
end

local function ask(prompt, then_fn)
	return function()
		vim.ui.input({ prompt = prompt }, function(answer)
			if answer and answer ~= "" then
				then_fn(answer)
			end
		end)
	end
end

return {
	-- Session --------------------------------------------------------------
	{
		"<F5>",
		function()
			dap().continue()
		end,
		desc = "Debug: start / continue",
	},
	{
		"<F10>",
		function()
			dap().step_over()
		end,
		desc = "Debug: step over",
	},
	{
		"<F11>",
		function()
			dap().step_into()
		end,
		desc = "Debug: step into",
	},
	{
		"<S-F11>",
		function()
			dap().step_out()
		end,
		desc = "Debug: step out",
	},
	{
		"<F9>",
		function()
			dap().toggle_breakpoint()
		end,
		desc = "Debug: toggle breakpoint",
	},

	{
		"<leader>dc",
		function()
			dap().continue()
		end,
		desc = "Debug: start / continue",
	},
	{
		"<leader>do",
		function()
			dap().step_over()
		end,
		desc = "Debug: step over",
	},
	{
		"<leader>di",
		function()
			dap().step_into()
		end,
		desc = "Debug: step into",
	},
	{
		"<leader>du",
		function()
			dap().step_out()
		end,
		desc = "Debug: step out",
	},
	{
		"<leader>dC",
		function()
			dap().run_to_cursor()
		end,
		desc = "Debug: run to cursor",
	},
	{
		"<leader>dp",
		function()
			dap().pause()
		end,
		desc = "Debug: pause",
	},
	{
		"<leader>dR",
		function()
			dap().restart()
		end,
		desc = "Debug: restart",
	},
	{
		"<leader>dl",
		function()
			dap().run_last()
		end,
		desc = "Debug: run last configuration",
	},
	{
		"<leader>dq",
		function()
			dap().terminate()
		end,
		desc = "Debug: terminate",
	},

	-- Breakpoints ------------------------------------------------------------
	{
		"<leader>dt",
		function()
			dap().toggle_breakpoint()
		end,
		desc = "Debug: toggle breakpoint",
	},
	{
		"<leader>dB",
		ask("Break when: ", function(cond)
			dap().set_breakpoint(cond)
		end),
		desc = "Debug: conditional breakpoint",
	},
	{
		"<leader>dL",
		ask("Log message ({expr} interpolates): ", function(msg)
			dap().set_breakpoint(nil, nil, msg)
		end),
		desc = "Debug: logpoint",
	},
	{
		"<leader>db",
		function()
			dap().list_breakpoints()
		end,
		desc = "Debug: list breakpoints",
	},
	{
		"<leader>dx",
		function()
			dap().clear_breakpoints()
		end,
		desc = "Debug: clear all breakpoints",
	},
	{
		"<leader>dE",
		function()
			dap().set_exception_breakpoints()
		end,
		desc = "Debug: exception breakpoints",
	},

	-- Inspect ----------------------------------------------------------------
	{
		"<leader>de",
		function()
			ui().eval()
		end,
		mode = { "n", "v" },
		desc = "Debug: evaluate expression",
	},
	{
		"<leader>dw",
		function()
			ui().watch(ui().expression())
		end,
		mode = { "n", "v" },
		desc = "Debug: watch expression",
	},
	{
		"<leader>ds",
		function()
			ui().scopes()
		end,
		desc = "Debug: variables in scope",
	},
	{
		"<leader>df",
		function()
			ui().frames()
		end,
		desc = "Debug: call stack",
	},
	{
		"<leader>dU",
		function()
			ui().toggle()
		end,
		desc = "Debug: toggle UI",
	},
	{
		"<leader>dr",
		function()
			dap().repl.toggle()
		end,
		desc = "Debug: toggle REPL",
	},
}
