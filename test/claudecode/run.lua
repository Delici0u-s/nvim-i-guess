-- Headless Claude Code check. Runs with the full config:
--
--   nvim --headless -c "luafile test/claudecode/run.lua"
--
-- No real Claude is needed: a stand-in command runs in the Claude terminal,
-- and diffs are opened the way Claude's openDiff tool opens them (and closed
-- the way its close_tab tool does). Your saved quick-toggle picks are left
-- alone (a temporary state file is used). Exits non-zero on any failure.
--
-- Covers: server + lock file, terminal keys, every quick-toggle choice, and
-- the diff workflow in every layout, with the file open in several windows
-- and tabs, several diffs waiting at once, new files, both tab modes and a
-- tiny screen.

local failures = 0
local WAIT = 5000 -- upper bound for anything asynchronous, in ms

local function check(ok, what, detail)
	print(("%s  %s%s"):format(ok and "PASS" or "FAIL", what, (not ok and detail) and ("  -- " .. detail) or ""))
	if not ok then
		failures = failures + 1
	end
	return ok
end

local function keys(lhs)
	vim.api.nvim_feedkeys(vim.keycode(lhs), "xt", false)
end

-- Errors reported while the test runs (plugin logger + vim.notify).
local errors = {}
local notify = vim.notify
vim.notify = function(msg, level, ...)
	-- The plugin can't send answers back here (there's no real Claude client).
	if level == vim.log.levels.ERROR and not tostring(msg):find("No global response sender", 1, true) then
		errors[#errors + 1] = tostring(msg)
	end
	return notify(msg, level, ...)
end

-- 1. Setup --------------------------------------------------------------------
local settings = require("plugins.configs.tools.claudecode.settings")
local toggles = require("plugins.configs.tools.claudecode.toggles")
settings.state_file = vim.fn.tempname() .. ".json"
settings.fixed.terminal_cmd = "sleep 600" -- stand-in for `claude`
require("lazy").load({ plugins = { "claudecode.nvim" } })
toggles.reset() -- defaults, saved to the temp file

local claudecode = require("claudecode")
local port = claudecode.state.port
check(claudecode.state.server ~= nil and port ~= nil, "server running")
local lock =
	vim.fs.joinpath(vim.env.CLAUDE_CONFIG_DIR or vim.fs.joinpath(vim.env.HOME, ".claude"), "ide", port .. ".lock")
check(vim.uv.fs_stat(lock) ~= nil, "lock file written", lock)

-- Test files: a.lua and b.lua exist, c.lua is a new file Claude proposes.
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
local files = {}
for _, name in ipairs({ "a", "b", "c" }) do
	files[name] = vim.fs.joinpath(dir, name .. ".lua")
end
vim.fn.writefile({ "local a = 1", "return a" }, files.a)
vim.fn.writefile({ "local b = 1", "return b" }, files.b)

-- Layout: tab 1 has a.lua in two windows, tab 2 has b.lua; Claude on the side.
vim.cmd.edit(files.a)
vim.cmd.split()
vim.cmd.tabnew(files.b)
vim.cmd.ClaudeCode()
local terminal = require("claudecode.terminal")
vim.wait(WAIT, function()
	return terminal.get_active_terminal_bufnr() ~= nil
end)
vim.cmd.stopinsert()
local term_buf = terminal.get_active_terminal_bufnr()
check(term_buf ~= nil, "Claude terminal opens")
vim.wait(WAIT, function()
	return vim.fn.maparg("<C-x><C-x>", "t", false, true).buffer == 1
end)
vim.cmd.wincmd("p")

-- 2. Terminal keys --------------------------------------------------------------
vim.api.nvim_buf_call(term_buf, function()
	check(vim.fn.maparg("<C-x>", "t") == "<C-X>", "<C-x> goes to Claude in its terminal")
	check(vim.fn.maparg("<C-x><C-x>", "t") == "<C-\\><C-N>", "<C-x><C-x> leaves terminal mode there")
end)

-- 3. Quick toggles: every choice applies (config validates it) and is saved --
for _, toggle in ipairs(settings.toggles) do
	for _, choice in ipairs(toggle.choices) do
		local ok, err = pcall(toggles.set, toggle, choice)
		check(ok and toggles.current(toggle) == choice, ("toggle %s = %s"):format(toggle.id, choice.label), err)
	end
end
check(claudecode.state.port == port, "server keeps its port while toggling")
toggles.reset()
check(next(vim.json.decode(table.concat(vim.fn.readfile(settings.state_file)))) == nil, "reset saves no picks")

local function pick(id, label)
	for _, toggle in ipairs(settings.toggles) do
		if toggle.id == id then
			for _, choice in ipairs(toggle.choices) do
				if choice.label == label then
					return toggles.set(toggle, choice)
				end
			end
		end
	end
	error(("no toggle %s = %s"):format(id, label))
end

-- 4. Diffs ----------------------------------------------------------------------
local diff = require("claudecode.diff")
local results = {}
local count = 0

--- Open a diff as Claude's openDiff tool does; returns its name.
local function propose(file, contents)
	count = count + 1
	local name = ("✻ [Claude Code] %s (test %d) ⧉"):format(vim.fs.basename(file), count)
	coroutine.wrap(function()
		results[name] = diff.open_diff_blocking(file, file, contents, name, nil)
	end)()
	return name
end

local function answer(name)
	vim.wait(WAIT, function()
		return results[name] ~= nil
	end)
	return results[name] and results[name].content[1].text
end

local function proposed_win(name)
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.b[vim.api.nvim_win_get_buf(win)].claudecode_diff_tab_name == name then
			return win
		end
	end
end

--- Claude's close_tab after an answer.
local function close_tab(name)
	diff.close_diff_by_tab_name(name)
	vim.wait(100) -- the plugin reloads buffers on a timer after an accept
end

-- What must be the same after a diff is closed: each tab's windows and their
-- files (floats such as notifications come and go on their own).
local function snapshot()
	local tabs = {}
	for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
		local wins = vim.tbl_filter(function(w)
			return vim.api.nvim_win_get_config(w).relative == ""
		end, vim.api.nvim_tabpage_list_wins(tab))
		local bufs = vim.tbl_map(vim.api.nvim_win_get_buf, wins)
		tabs[#tabs + 1] = table.concat(
			vim.tbl_map(function(b)
				return vim.fs.basename(vim.api.nvim_buf_get_name(b))
			end, bufs),
			","
		)
	end
	return table.concat(tabs, " | ")
end

local proposal = "local a = 2\nreturn a\n"
local layouts = { "side by side", "stacked", "unified (one window)" }
local tab_modes = { "a new tab per diff", "the current tab" }

for _, tab_mode in ipairs(tab_modes) do
	pick("diff_tab", tab_mode)
	for _, layout in ipairs(layouts) do
		pick("diff_layout", layout)
		local where = ("[%s, %s]"):format(layout, tab_mode)
		vim.cmd("1tabnext | 1wincmd w")
		local before = snapshot()

		-- <C-s> in the proposed window accepts, with your edits.
		local name = propose(files.a, proposal)
		local win = proposed_win(name)
		if check(win ~= nil, where .. " diff opens") then
			vim.api.nvim_set_current_win(win)
			-- Unified diffs are read-only; the split layouts let you edit first.
			local editable = vim.bo.modifiable
			if editable then
				vim.api.nvim_buf_set_lines(0, -1, -1, false, { "-- edited" })
			end
			keys("<C-s>")
			check(answer(name) == "FILE_SAVED", where .. " <C-s> accepts")
			local text = results[name] and results[name].content[2].text or ""
			check(
				text:find("local a = 2", 1, true) and (not editable or text:find("-- edited", 1, true)),
				where .. (editable and " your edits go along" or " the proposal goes along"),
				text
			)
			close_tab(name)
			check(snapshot() == before, where .. " windows and tabs restored", snapshot() .. "  vs  " .. before)
		end

		-- <C-q> in the proposed window rejects.
		name = propose(files.a, proposal)
		win = proposed_win(name)
		if win then
			vim.api.nvim_set_current_win(win)
			keys("<C-q>")
			check(answer(name) == "DIFF_REJECTED", where .. " <C-q> rejects")
			close_tab(name)
			check(snapshot() == before, where .. " restored after reject", snapshot() .. "  vs  " .. before)
		end

		-- <leader>aa from another window of the diff's tab (or the first tab).
		name = propose(files.a, proposal)
		win = proposed_win(name)
		if win then
			local other = vim.tbl_filter(function(w)
				return w ~= win and vim.api.nvim_win_get_config(w).relative == ""
			end, vim.api.nvim_tabpage_list_wins(vim.api.nvim_win_get_tabpage(win)))[1]
			vim.api.nvim_set_current_win(other or vim.api.nvim_list_wins()[1])
			keys("<leader>aa")
			check(answer(name) == "FILE_SAVED", where .. " <leader>aa from another window accepts")
			close_tab(name)
		end
	end
end
pick("diff_tab", tab_modes[1])
pick("diff_layout", layouts[1])

-- Several diffs at once (one per tab), answered from an unrelated tab.
vim.cmd("1tabnext")
local before = snapshot()
local select = vim.ui.select
local offered
vim.ui.select = function(items, opts, on_choice)
	offered = #items
	on_choice(items[2], 2)
end
local names = { propose(files.a, proposal), propose(files.b, "return 2\n"), propose(files.c, "return 3\n") }
vim.cmd("1tabnext")
keys("<leader>aj")
check(offered == 3, "3 waiting diffs offered", tostring(offered))
check(vim.b.claudecode_diff_tab_name == names[2], "<leader>aj jumps to the picked diff")
vim.cmd("1tabnext")
keys("<leader>ad")
check(answer(names[2]) == "DIFF_REJECTED", "<leader>ad rejects the picked diff")
close_tab(names[2])
vim.ui.select = select
check(results[names[1]] == nil and results[names[3]] == nil, "the other diffs still wait")
vim.api.nvim_set_current_win(proposed_win(names[3]))
keys("<C-x>")
check(answer(names[3]) == "FILE_SAVED", "new file: <C-x> accepts")
check(results[names[3]] and results[names[3]].content[2].text == "return 3\n", "new file: content as proposed")
check(vim.uv.fs_stat(files.c) == nil, "new file: Neovim doesn't write it (Claude does)")
close_tab(names[3])
keys("<leader>ax")
check(answer(names[1]) == "DIFF_REJECTED", "<leader>ax rejects what's left")
vim.cmd("1tabnext")
check(snapshot() == before, "all diffs closed: windows and tabs restored", snapshot() .. "  vs  " .. before)

-- A tiny screen.
local columns, lines = vim.o.columns, vim.o.lines
vim.o.columns, vim.o.lines = 40, 12
local name = propose(files.a, proposal)
local win = proposed_win(name)
check(win ~= nil and vim.api.nvim_win_get_width(win) > 0, "tiny screen: diff opens")
if win then
	vim.api.nvim_set_current_win(win)
	keys("<C-s>")
	check(answer(name) == "FILE_SAVED", "tiny screen: <C-s> accepts")
	close_tab(name)
end
vim.o.columns, vim.o.lines = columns, lines

-- 5. Wrap up ---------------------------------------------------------------------
check(vim.api.nvim_buf_is_valid(term_buf), "Claude terminal survives every diff")
check(#errors == 0, "no errors reported", table.concat(errors, " | "))
vim.fn.delete(dir, "rf")
os.remove(settings.state_file)
print(("\n%s"):format(failures == 0 and "all passed" or (failures .. " failed")))
vim.cmd(failures == 0 and "qa!" or "cq!")
