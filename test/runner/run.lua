-- Headless check of the project runner (utils/runner.lua): every target
-- (shell terminals, dedicated split/vsplit, external), focus staying in the
-- editor, run folder (file's folder / root), % expansion, stopping,
-- per-project memory and prompt completion.
--
--   nvim --headless -c "luafile test/runner/run.lua"
--
-- Uses a temp project, a temp state file and a stand-in external terminal.
-- Exits non-zero on any failure.

local failures = 0

local function check(ok, what, detail)
	print(("%s  %s%s"):format(ok and "PASS" or "FAIL", what, (not ok and detail) and ("  -- " .. detail) or ""))
	if not ok then
		failures = failures + 1
	end
	return ok
end

local runner = require("utils.runner")

local term = require("utils.terminal")
local tmp = vim.fn.tempname()
runner.settings.state_file = vim.fs.joinpath(tmp, "state", "runner.json")
-- Stand-in for a terminal emulator: runs the command and exits, like a
-- window that closes when done.
require("utils.shell").settings.external = { "env" }

local notes = {}
vim.notify = function(msg)
	notes[#notes + 1] = tostring(msg)
end
local function wait_note(pat)
	return vim.wait(8000, function()
		for _, n in ipairs(notes) do
			if n:find(pat, 1, true) then
				return true
			end
		end
	end, 20)
end
local function text(buf)
	return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
end
local function wait_text(buf, s)
	return vim.wait(8000, function()
		return text(buf):find(s, 1, true) ~= nil
	end, 20)
end

local proj = vim.fs.joinpath(tmp, "proj")
local src = vim.fs.joinpath(proj, "src")
vim.fn.mkdir(vim.fs.joinpath(proj, ".git"), "p")
vim.fn.mkdir(vim.fs.joinpath(src, "sub dir"), "p")
local file = vim.fs.joinpath(src, "main file.txt") -- a space: % must be quoted
vim.fn.writefile({ "hello" }, file)
vim.fn.writefile({ "#!/bin/sh", "echo SCRIPT_OK" }, vim.fs.joinpath(src, "run.sh"))
vim.fn.setfperm(vim.fs.joinpath(src, "run.sh"), "rwxr-xr-x")
for i = 1, 40 do -- many files, long names
	vim.fn.writefile({}, vim.fs.joinpath(src, ("many_%02d_%s.txt"):format(i, ("y"):rep(i * 2))))
end
vim.cmd.edit(vim.fn.fnameescape(file))
local editor = vim.api.nvim_get_current_win()
local editor_buf = vim.api.nvim_get_current_buf()

check(runner.root() == proj, "root found by marker", runner.root())
check(runner.project().target == "vertical" and runner.project().cwd == "file", "defaults: <C-n> shell, file's folder")
check(runner.dir() == src, "runs from the file's folder", runner.dir())

local function terminals()
	return vim.tbl_filter(function(w)
		return vim.bo[vim.api.nvim_win_get_buf(w)].buftype == "terminal"
	end, vim.api.nvim_tabpage_list_wins(0))
end

-- Dedicated split: relative names and % work from the file's folder ----
runner.set_target("split")
runner.set("pwd && cat % && cat ./main\\ file.txt && ./run.sh")
runner.run()
check(vim.api.nvim_get_current_win() == editor, "split: focus stays in the editor")
check(wait_note("✓"), "split: success notified", table.concat(notes, "; "))
local wins = terminals()
check(#wins == 1, "split: one output window")
local out = vim.api.nvim_win_get_buf(wins[1])
local o = text(out)
check(o:find(src, 1, true) and select(2, o:gsub("hello", "")) == 2, "split: ran in file's folder, % and ./ resolved", o)
check(o:find("SCRIPT_OK", 1, true), "split: ./script relative to the file runs")
local split_win = wins[1]
check(vim.api.nvim_win_get_width(split_win) == vim.o.columns, "split: full-width below")

notes = {}
runner.run("echo RUN2; exit 3")
check(wait_note("exit 3"), "split: failure notified with code", table.concat(notes, "; "))
wins = terminals()
check(#wins == 1 and not text(vim.api.nvim_win_get_buf(wins[1])):find("hello"), "split: rerun reuses window, replaces output")

-- vsplit replaces the split rather than adding a window.
runner.set_target("vsplit")
notes = {}
runner.run("echo VS")
wait_note("✓")
wins = terminals()
check(#wins == 1 and vim.api.nvim_win_get_height(wins[1]) > vim.api.nvim_win_get_height(editor) / 2, "vsplit: one window, side by side")
runner.toggle_output()
check(#terminals() == 0, "toggle hides dedicated output")
runner.toggle_output()
check(#terminals() == 1, "toggle shows it again")
runner.toggle_output()

-- root mode ---------------------------------------------------------------
runner.set_cwd("root")
check(runner.dir() == proj, "<leader>rd: runs from project root", runner.dir())
notes = {}
runner.run("pwd; printf '[%%s]' % %:t %<")
wait_note("✓")
-- Joined without newlines: the narrow vsplit terminal hard-wraps long lines.
o = table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(terminals()[1]), 0, -1, false), "")
check(o:find("[src/main file.txt][main file.txt][src/main file]", 1, true), "root: % relative to root, :t and %<", o)

-- <leader>rd picker: browse to a folder, type a path, back to the file's folder.
local orig_select, orig_input = vim.ui.select, vim.ui.input
local function answer_select(labels)
	local step = 0
	vim.ui.select = function(items, opts, cb)
		step = step + 1
		local want = labels[step]
		cb(want and vim.iter(items):find(function(i)
			local label = opts.format_item(i)
			return type(label) == "string" and vim.trim(label):find(want, 1, true) == 1
				or (type(label) == "string" and label:find(want, 1, true))
		end))
	end
end
answer_select({ "Choose folder…", "src/", "sub dir/", "✓ Use this folder" }) -- browses from the root
runner.pick_cwd()
check(runner.dir() == vim.fs.joinpath(src, "sub dir"), "pick_cwd: browsed folder", runner.dir())
answer_select({ "Type a path…" })
vim.ui.input = function(_, cb)
	cb(proj .. "/")
end
runner.pick_cwd()
check(runner.dir() == proj, "pick_cwd: typed folder", runner.dir())
answer_select({ "Current file's folder" })
runner.pick_cwd()
check(runner.dir() == src and runner.project().cwd == "file", "pick_cwd: back to the file's folder", runner.dir())
vim.ui.select, vim.ui.input = orig_select, orig_input

-- dedicated runs go through the user's shell, with its rc (aliases)
notes = {}
runner.run("echo $0")
wait_note("✓")
o = table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(terminals()[1]), 0, -1, false), "")
check(o:find(vim.fs.basename(vim.o.shell), 1, true), "dedicated: runs in the user's shell", o)

-- Shell terminal (<C-n>) --------------------------------------------------
runner.set_target("vertical")
notes = {}
runner.run("pwd && echo SHELL_RUN")
check(vim.api.nvim_get_current_win() == editor, "shell: focus stays in the editor")
check(term.visible("vertical"), "shell: <C-n> terminal shown")
local shell = term.ensure("vertical")
check(wait_text(shell, "SHELL_RUN"), "shell: command typed into <C-n> terminal", text(shell))
check(wait_note("✓"), "shell: end noticed (exit status via OSC)", table.concat(notes, "; "))
-- Joined without newlines: the narrow split hard-wraps long lines.
local function flat(buf)
	return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "")
end
check(flat(shell):find(". ~/" .. vim.fs.relpath(vim.env.HOME, runner.helper_file()), 1, true), "shell: helper sourced once")
-- Second run: helper known, folder known from OSC 7 -> just `nrun cmd`.
notes = {}
runner.run("echo SHORT_LINE")
wait_note("✓")
-- The exit OSC can arrive before the terminal text is redrawn into the buffer.
vim.wait(5000, function()
	return flat(shell):find("SHORT_LINE.*SHORT_LINE") ~= nil
end, 20)
-- Everything typed after the first run's output.
local later = flat(shell):match(".*SHELL_RUN(.*)$") or "" -- after the last one: the output
local helper = runner.settings.helper_name
check(later:find(helper .. " echo SHORT_LINE", 1, true) and not later:find(helper .. " -C", 1, true), "shell: short line `nrun cmd`", later)
check(not later:find("nrun.sh", 1, true), "shell: helper not sourced again", later)
notes = {}
runner.run("echo a && echo QUOTED_OK")
check(wait_text(shell, "QUOTED_OK") and wait_note("✓"), "shell: operators passed quoted, run as one command")
notes = {}
runner.run("false")
check(wait_note("exit 1"), "shell: failure code reported", table.concat(notes, "; "))
-- The shell's own folder is untouched (command ran in a subshell).
vim.fn.chansend(vim.bo[shell].channel, "echo SHELLPWD=$PWD\r")
check(wait_text(shell, "SHELLPWD="), "shell still responsive")
check(not text(shell):find("SHELLPWD=" .. src, 1, true), "shell: its own cwd unchanged")

-- A busy shell gets interrupted, then the new run goes in.
notes = {}
runner.run("sleep 30")
vim.wait(300)
runner.run("echo AFTER_INTERRUPT")
check(wait_text(shell, "AFTER_INTERRUPT"), "shell: busy run interrupted, new one runs", text(shell))
check(wait_note("echo AFTER_INTERRUPT"), "shell: new run's end noticed")
notes = {}
runner.run("sleep 30")
vim.wait(300)
runner.stop()
check(wait_note("exit 130"), "shell: stop interrupts", table.concat(notes, "; "))
check(#vim.tbl_filter(function(w) -- toggling via the runner hides <C-n>
	return vim.api.nvim_win_get_buf(w) == shell
end, vim.api.nvim_tabpage_list_wins(0)) == 1, "shell: one <C-n> window")
runner.toggle_output()
check(not term.visible("vertical"), "toggle hides the <C-n> terminal")

-- horizontal shell, picked for one run only
notes = {}
runner.run("echo HSHELL", { target = "horizontal" })
check(term.visible("horizontal") and vim.api.nvim_get_current_win() == editor, "horizontal shell: shown, focus kept")
check(wait_note("✓"), "horizontal shell: end noticed")
check(runner.project().target == "vertical", "one-off target not remembered")

-- external --------------------------------------------------------------
runner.set_target("external")
notes = {}
local before = #terminals()
runner.run("test \"$(pwd)\" = " .. vim.fn.shellescape(src) .. " && cat % >/dev/null")
check(wait_note("✓"), "external: ran in file's folder, status read back", table.concat(notes, "; "))
check(#terminals() == before, "external: no window opened in nvim")
notes = {}
runner.run("exit 4")
check(wait_note("exit 4"), "external: failure code", table.concat(notes, "; "))
require("utils.shell").settings.external = { "sh", "-c", "exit 0" } -- emulator that hands off and returns at once
notes = {}
runner.run("true")
check(wait_note("exit status unknown"), "external: handed-off window reported as unknown", table.concat(notes, "; "))
require("utils.shell").settings.external = { "env" }

-- persistence + projects ---------------------------------------------
local saved = vim.json.decode(table.concat(vim.fn.readfile(runner.settings.state_file), "\n"))
check(saved[proj] and saved[proj].target == "external" and saved[proj].cmd, "settings persisted per project")
local other = vim.fs.joinpath(tmp, "other")
vim.fn.mkdir(vim.fs.joinpath(other, ".git"), "p")
vim.cmd.edit(vim.fn.fnameescape(vim.fs.joinpath(other, "x.txt")))
check(runner.project().cmd == nil and runner.project().target == runner.settings.target, "other project starts at defaults")
vim.cmd.buffer(editor_buf)

-- run on save
runner.set_target("split")
runner.set("echo SAVED")
notes = {}
runner.on_save()
check(not vim.wait(500, function()
	return #notes > 0
end), "on_save does nothing while off")
runner.toggle_on_save()
notes = {}
runner.on_save()
check(wait_note("✓ echo SAVED"), "on_save runs when on")

-- focus mode: cursor in the output while it runs, back after ------------
runner.toggle_on_save() -- off again
for _, target in ipairs({ "split", "vertical" }) do
	runner.set_target(target)
	runner.toggle_focus()
	check(runner.project().focus, target .. ": focus on")
	notes = {}
	runner.run("read x; echo GOT=$x")
	local out_win = vim.api.nvim_get_current_win()
	local out_buf = vim.api.nvim_win_get_buf(out_win)
	check(out_win ~= editor and vim.bo[out_buf].buftype == "terminal", target .. ": cursor moved into the output")
	vim.wait(1000) -- let the program start reading
	vim.fn.chansend(vim.bo[out_buf].channel, "typed\r") -- what you'd type there
	check(wait_text(out_buf, "GOT=typed"), target .. ": program read the input")
	check(wait_note("✓"), target .. ": run ended")
	check(vim.api.nvim_get_current_win() == editor, target .. ": back in the editor afterwards")
	-- moved elsewhere meanwhile -> stays there
	notes = {}
	runner.run("read x")
	out_buf = vim.api.nvim_get_current_buf() -- a dedicated run makes a new buffer
	vim.wait(1000)
	vim.api.nvim_set_current_win(editor)
	local other_win = vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), true, { split = "above" })
	vim.fn.chansend(vim.bo[out_buf].channel, "x\r")
	wait_note("✓")
	check(vim.api.nvim_get_current_win() == other_win, target .. ": no jump back if you moved on")
	vim.api.nvim_win_close(other_win, true)
	vim.api.nvim_set_current_win(editor)
	runner.toggle_focus()
end

-- menu: shows current values, settings reopen it, run closes it
local shown = {}
local step = 0
vim.ui.select = function(items, opts, cb)
	step = step + 1
	shown[step] = vim.tbl_map(opts.format_item, items)
	if step == 1 then
		cb(vim.iter(items):find(function(i)
			return opts.format_item(i):find("^Focus output")
		end))
	else
		cb(nil)
	end
end
runner.menu()
vim.wait(1000, function()
	return step >= 2
end)
vim.ui.select = orig_select
local first = table.concat(shown[1] or {}, " | ")
check(first:find("Command:", 1, true) and first:find("Runs in:", 1, true) and first:find("Folder:", 1, true), "menu lists settings", first)
check(first:find("Focus output:  off", 1, true), "menu shows focus off", first)
check((shown[1] or {})[1] == "Run now", "menu: first entry is just \"Run now\"", (shown[1] or {})[1])
check(table.concat(shown[2] or {}, " | "):find("Focus output:  on", 1, true), "menu reopened with focus now on")
runner.toggle_focus()

-- completion ------------------------------------------------------------
-- (with the user's shell; zsh/fish give their own completion)
local function complete_in(line)
	local b = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(b, 0, -1, false, { line })
	local w = vim.api.nvim_open_win(b, true, { relative = "editor", row = 0, col = 0, width = 80, height = 1 })
	vim.api.nvim_win_set_cursor(w, { 1, #line })
	local lead = line:match("%S*$")
	local res = vim.fn.getcompletion(lead, runner.completion) -- as snacks.input calls it
	vim.api.nvim_win_close(w, true)
	return res
end
-- Through the real prompt: completion runs inside the prompt's own buffer,
-- and must still use the run folder of the buffer the prompt came from.
local res
local input = vim.ui.input
vim.ui.input = function(opts, cb)
	res = complete_in("cat ma")
	check(opts.completion == runner.completion, "prompt asks for runner completion")
	cb(nil)
end
runner.set_cmd(false)
vim.ui.input = input
check(vim.tbl_contains(res, "main\\ file.txt"), "complete: files relative to the run folder, from the prompt", vim.inspect(res))
check(vim.tbl_contains(complete_in("ech"), "echo"), "complete: first word is a command")
check(vim.tbl_contains(complete_in("make && ech"), "echo"), "complete: command after &&")
local orig_dir = runner.dir
runner.dir = function()
	return src
end
check(vim.tbl_contains(complete_in("zig run ma"), "main\\ file.txt"), "complete: argument is a file")
check(vim.tbl_contains(complete_in("./ru"), "./run.sh"), "complete: ./ in first word is a file")
check(vim.tbl_contains(complete_in("cat sub"), "sub\\ dir/"), "complete: folders get /")
check(#complete_in("cat many_") == 40, "complete: many files", #complete_in("cat many_"))
local up = complete_in("cat ../sr")
check(vim.tbl_contains(up, "../src/") or vim.tbl_contains(up, "../src"), "complete: ../ walks up", vim.inspect(up))
if require("utils.shell").kind() == "zsh" then
	check(vim.tbl_contains(complete_in("git sw"), "switch"), "zsh: subcommands (git sw -> switch)")
	check(vim.tbl_contains(complete_in("ls --al"), "--all"), "zsh: options (ls --al -> --all)")
	check(vim.tbl_contains(complete_in("echo $HO"), "$HOME"), "zsh: variables ($HO -> $HOME)")
end
-- A shell whose completion can't be asked falls back to commands + files.
local real_shell = vim.o.shell
vim.o.shell = "sh"
check(vim.tbl_contains(complete_in("cat ma"), "main\\ file.txt") and vim.tbl_contains(complete_in("ech"), "echo"), "fallback completion for other shells")
vim.o.shell = real_shell
runner.dir = orig_dir

-- live suggestions in the snacks prompt, without <Tab>
require("lazy").load({ plugins = { "snacks.nvim" } })
Snacks.input.enable()
vim.cmd.buffer(editor_buf)
runner.set_cmd(false)
local prompt = vim.api.nvim_get_current_buf()
check(vim.bo[prompt].filetype == "snacks_input", "prompt is snacks.input")
for _, lhs in ipairs({ "<C-J>", "<C-K>", "<CR>" }) do
	local m = vim.fn.maparg(lhs, "i", false, true)
	check(m.buffer == 1 and (m.desc or ""):find("^Run prompt:"), "prompt: " .. lhs .. " navigates suggestions like LSP completion")
end
-- Insert mode and complete() need a real UI (checked by hand in tmux);
-- here the mode is faked and complete() recorded.
vim.api.nvim_buf_set_lines(prompt, 0, -1, false, { "cat ma" })
vim.api.nvim_win_set_cursor(0, { 1, 6 })
local real_mode, real_complete = vim.fn.mode, vim.fn.complete
local offered
vim.fn.mode = function()
	return "i"
end
vim.fn.complete = function(startcol, items)
	offered = { startcol = startcol, items = items }
end
vim.api.nvim_exec_autocmds("TextChangedI", { buffer = prompt })
vim.wait(5000, function()
	return offered ~= nil
end, 20)
check(offered and offered.startcol == 5 and vim.tbl_contains(offered.items, "main\\ file.txt"), "live: suggestions offered while typing, for the last word", vim.inspect(offered))
-- typed on before the answer came: the stale answer is dropped
offered = nil
vim.api.nvim_exec_autocmds("TextChangedI", { buffer = prompt })
vim.wait(runner.settings.live_delay + 20)
vim.api.nvim_buf_set_lines(prompt, 0, -1, false, { "cat mai" })
vim.api.nvim_win_set_cursor(0, { 1, 7 })
vim.wait(1500)
check(offered == nil, "live: stale suggestions dropped", vim.inspect(offered))
vim.fn.mode, vim.fn.complete = real_mode, real_complete
vim.api.nvim_win_close(0, true)

vim.fn.delete(tmp, "rf")
print(failures == 0 and "ALL PASS" or (failures .. " FAILURE(S)"))
vim.cmd(failures == 0 and "qa!" or "cq!")
