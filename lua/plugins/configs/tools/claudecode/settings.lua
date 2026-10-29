-- Claude Code settings: the one home for every option. Plain tables, no plugin
-- requires.
--
-- `toggles` are changeable at runtime from the quick-toggle menu (<leader>ao,
-- toggles.lua). Each has a label, the choices (first = default) and where its
-- value goes in claudecode.nvim's options. Picked values are saved to
-- `state_file` and applied on top of the defaults at startup. To add a toggle,
-- add an entry here; nothing else needs to change.
--
-- `fixed` options aren't in the menu: they only take effect when the server
-- starts.
local M = {}

M.state_file = vim.fs.joinpath(vim.fn.stdpath("state"), "claudecode.json")

M.fixed = {
	track_selection = true, -- Claude sees your current selection
}

---@class ClaudeToggleChoice
---@field label string shown in the menu
---@field value table claudecode.nvim options this choice sets (deep-merged)
---@field kind? string choices of different kinds don't apply to a running session

---@class ClaudeToggle
---@field id string key in the state file
---@field label string
---@field choices ClaudeToggleChoice[] first one is the default
---@field on_open? boolean takes effect when the Claude window next opens

---@type ClaudeToggle[]
M.toggles = {
	{
		id = "window",
		label = "Claude window",
		on_open = true,
		-- Splits use the plugin's native terminal: snacks' terminal closes
		-- itself on ExitPre, which cancels the first :qa! while Claude runs
		-- (the second one quits). Floating needs snacks, so it keeps that.
		-- `kind`: a running Claude session keeps its window kind, so switching
		-- between kinds applies to the next session (left/right/width apply
		-- when the window is next shown).
		choices = {
			{
				label = "split, right",
				kind = "split",
				value = { terminal = { provider = "native", split_side = "right" } },
			},
			{
				label = "split, left",
				kind = "split",
				value = { terminal = { provider = "native", split_side = "left" } },
			},
			{
				label = "floating (snacks; :qa! twice while Claude runs)",
				kind = "float",
				value = {
					terminal = {
						provider = "snacks",
						snacks_win_opts = { position = "float", width = 0.9, height = 0.9 },
					},
				},
			},
			{
				label = "none (run `claude` elsewhere, connect with /ide)",
				kind = "none",
				value = { terminal = { provider = "none" } },
			},
		},
	},
	{
		id = "width",
		label = "Claude split width",
		on_open = true,
		choices = {
			{ label = "30%", value = { terminal = { split_width_percentage = 0.30 } } },
			{ label = "40%", value = { terminal = { split_width_percentage = 0.40 } } },
			{ label = "50%", value = { terminal = { split_width_percentage = 0.50 } } },
			{ label = "20%", value = { terminal = { split_width_percentage = 0.20 } } },
		},
	},
	{
		id = "diff_tab",
		label = "Diffs open in",
		choices = {
			{ label = "a new tab per diff", value = { diff_opts = { open_in_new_tab = true } } },
			{ label = "the current tab", value = { diff_opts = { open_in_new_tab = false } } },
		},
	},
	{
		id = "diff_layout",
		label = "Diff layout",
		choices = {
			{ label = "side by side", value = { diff_opts = { layout = "vertical" } } },
			{ label = "stacked", value = { diff_opts = { layout = "horizontal" } } },
			{ label = "unified (one window)", value = { diff_opts = { layout = "unified" } } },
		},
	},
	{
		id = "diff_terminal",
		label = "Claude terminal in diff tabs",
		choices = {
			{ label = "shown", value = { diff_opts = { hide_terminal_in_new_tab = false } } },
			{ label = "hidden", value = { diff_opts = { hide_terminal_in_new_tab = true } } },
		},
	},
	{
		id = "diff_focus",
		label = "When a diff opens, focus",
		choices = {
			{ label = "the diff", value = { diff_opts = { keep_terminal_focus = false } } },
			{ label = "the Claude terminal", value = { diff_opts = { keep_terminal_focus = true } } },
		},
	},
	{
		id = "send_focus",
		label = "After sending to Claude, focus",
		choices = {
			{ label = "stay where you are", value = { focus_after_send = false } },
			{ label = "the Claude terminal", value = { focus_after_send = true } },
		},
	},
	{
		id = "log_level",
		label = "Log level",
		choices = {
			{ label = "info", value = { log_level = "info" } },
			{ label = "warn", value = { log_level = "warn" } },
			{ label = "debug", value = { log_level = "debug" } },
			{ label = "trace", value = { log_level = "trace" } },
		},
	},
}

return M
