-- Quick-toggle menu for the Claude Code options in settings.lua (<leader>ao).
--
-- Picks are saved to settings.state_file (outside the repo) and applied live:
-- claudecode.nvim's terminal, diff and logger modules are set up again with
-- the new options, which keeps the server and the Claude connection running.
-- The plugin has no public "update config" API, so apply() also replaces
-- `require("claudecode").state.config`; if a plugin update breaks live
-- toggling, look there first.
local settings = require("plugins.configs.tools.claudecode.settings")

local M = {}

-- Saved picks: toggle id -> choice label. Read once, on first use.
local saved

local function load()
	if saved then
		return saved
	end
	saved = {}
	local fd = io.open(settings.state_file, "r")
	if fd then
		local ok, data = pcall(vim.json.decode, fd:read("*a"))
		fd:close()
		saved = ok and type(data) == "table" and data or {}
	end
	return saved
end

local function save()
	vim.fn.mkdir(vim.fs.dirname(settings.state_file), "p")
	local fd = io.open(settings.state_file, "w")
	if not fd then
		vim.notify("Claude: can't write " .. settings.state_file, vim.log.levels.WARN)
		return
	end
	fd:write(vim.json.encode(saved))
	fd:close()
end

--- The current choice of a toggle: the saved one if it still exists, else
--- the default (first).
---@param toggle ClaudeToggle
function M.current(toggle)
	local label = load()[toggle.id]
	for _, choice in ipairs(toggle.choices) do
		if choice.label == label then
			return choice
		end
	end
	return toggle.choices[1]
end

-- Toggle id -> choice whose options the plugin has now.
local applied = {}

local ended = {} -- terminal buffers whose job exited

--- The running Claude terminal's buffer, if any (only asked once the plugin
--- is set up, i.e. after the first apply). A terminal whose job exited counts
--- as gone even while the plugin still reports it.
local function running()
	local buf = next(applied) and require("claudecode.terminal").get_active_terminal_bufnr() or nil
	return not ended[buf] and buf or nil
end

--- The choice to give the plugin: the current one, except that a running
--- session keeps its window kind. Switching kind also switches the terminal
--- provider, and the plugin would lose track of the running Claude.
local function effective(toggle)
	local choice, prev = M.current(toggle), applied[toggle.id]
	if prev and choice.kind ~= prev.kind and running() then
		return prev, true
	end
	return choice, false
end

local deferred_for -- buffer whose exit re-applies held-back choices

--- claudecode.nvim options: the fixed settings plus every toggle's choice.
function M.options()
	local opts = vim.deepcopy(settings.fixed)
	local held = false
	for _, toggle in ipairs(settings.toggles) do
		local choice, kept = effective(toggle)
		applied[toggle.id] = choice
		held = held or kept
		opts = vim.tbl_deep_extend("force", opts, choice.value)
	end
	local buf = held and running()
	if buf and deferred_for ~= buf then
		deferred_for = buf
		vim.api.nvim_create_autocmd("TermClose", {
			buffer = buf,
			once = true,
			desc = "Claude: apply held-back option changes",
			callback = vim.schedule_wrap(function()
				ended[buf], deferred_for = true, nil
				M.apply()
			end),
		})
	end
	return opts
end

--- Apply the current options to the running plugin.
function M.apply()
	local opts = M.options()
	local config = require("claudecode.config").apply(opts) -- validates
	require("claudecode.logger").setup(config)
	require("claudecode.terminal").setup(opts.terminal, config.terminal_cmd, config.env)
	require("claudecode.diff").setup(config)
	require("claudecode").state.config = config
end

--- Set a toggle to a choice (nil = default), save and apply.
function M.set(toggle, choice)
	load()[toggle.id] = (choice and choice ~= toggle.choices[1]) and choice.label or nil
	save()
	M.apply()
end

function M.reset()
	saved = {}
	save()
	M.apply()
end

local function pick(items, prompt, format)
	vim.ui.select(items, { prompt = prompt, format_item = format }, function(item)
		if item then
			item.run()
		end
	end)
end

--- The menu: every toggle with its current value. Picking one lists its
--- choices; after a change the menu reopens, so several can be set in a row.
function M.menu()
	local width = 0
	for _, toggle in ipairs(settings.toggles) do
		width = math.max(width, vim.fn.strdisplaywidth(toggle.label))
	end
	local items = {}
	for _, toggle in ipairs(settings.toggles) do
		items[#items + 1] = {
			label = toggle.label,
			value = M.current(toggle).label,
			run = function()
				M.choose(toggle)
			end,
		}
	end
	items[#items + 1] = {
		label = "Reset all to defaults",
		run = function()
			M.reset()
			vim.notify("Claude: options reset to defaults")
			M.menu()
		end,
	}
	pick(items, "Claude Code options", function(item, chunks)
		local label = item.value and (item.label .. (" "):rep(width - vim.fn.strdisplaywidth(item.label))) or item.label
		if not chunks then
			return item.value and (label .. "  " .. item.value) or label
		end
		return item.value and { { label .. "  " }, { item.value, "Special" } } or { { label, "Comment" } }
	end)
end

---@param toggle ClaudeToggle
function M.choose(toggle)
	local current = M.current(toggle)
	local items = vim.tbl_map(function(choice)
		return {
			label = choice.label,
			current = choice == current,
			run = function()
				M.set(toggle, choice)
				local running = require("claudecode.terminal").get_active_terminal_bufnr() ~= nil
				local when = ""
				if running and choice.kind ~= current.kind then
					when = " (applies to the next Claude session; this one keeps its window)"
				elseif running and toggle.on_open then
					when = " (applies when the Claude window is next shown)"
				end
				vim.notify(("Claude: %s → %s%s"):format(toggle.label, choice.label, when))
				M.menu()
			end,
		}
	end, toggle.choices)
	pick(items, toggle.label, function(item, chunks)
		local mark = item.current and "● " or "  "
		if not chunks then
			return mark .. item.label
		end
		return { { mark, "Special" }, { item.label, item.current and "Special" or nil } }
	end)
end

return M
