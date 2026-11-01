-- Project runner: one build/run command per project, run where you choose
-- without leaving the window you're in. Replaces the "save, go to the
-- terminal, retype/repeat, come back" loop.
--
--   <leader>rS   menu: every action and setting below, with current values
--   <leader>rr   run it now           <leader>ro   show/hide output
--   <leader>rk   stop it              :Run [cmd]   run (cmd given: set it first)
--   settings, under <leader>rs:
--   <leader>rsc  set the command (remembered per project, across restarts)
--   <leader>rst  pick where it runs   <leader>rsd  pick the folder it runs in
--   <leader>rss  toggle run on <C-S>
--   <leader>rsf  toggle focus: cursor in the output while it runs (stdin),
--                back where you were when it exits
--
-- Where it runs (M.targets, remembered per project, default settings.target):
--   vertical / horizontal  typed into the <C-n> / <C-h>n shell (utils/terminal.lua)
--   split / vsplit         a dedicated output split, replaced on every run
--   external               a new terminal emulator window that closes when done
-- Everything runs in your shell (utils/shell.lua), with its rc file loaded.
--
-- Run folder (<leader>rsd): the current file's folder (default), the project
-- root, or a folder you pick. % is the current file relative to it
-- (:h filename-modifiers work, %< drops the extension, %% is a literal %).
-- <Tab> in the prompts gives your shell's own completion (zsh, fish), run
-- in that folder; other shells get commands + files.
--
-- In the shell terminals the line typed is `nrun [-C dir] cmd`: a small
-- function (settings.helper_name, written to M.helper_file()) that runs cmd
-- in a subshell and reports the exit status back. A shell that hasn't got
-- it yet sources it first; source it from your shell rc to skip that:
--   [ -n "$NVIM" ] && . ~/.local/state/nvim/runner/nrun.sh
--
-- A still-running previous run is stopped first. The exit status is a
-- notification. <A-e> (utils/jump.lua) jumps into the output and back.
-- Logic only -- keys in configs/keymaps/terminal.lua.

local shell = require("utils.shell")

local M = {}

M.settings = {
	-- Remembered settings per project, keyed by project root.
	state_file = vim.fn.stdpath("state") .. "/runner.json",
	-- Files/folders that mark a project root, nearest first; else cwd.
	root_markers = { ".git", "build.zig", "Cargo.toml", "Makefile", "CMakeLists.txt", "pyproject.toml", "package.json" },
	target = "vertical", -- default target, see M.targets
	cwd = "file", -- default run folder: "file" | "root" | an absolute path
	-- Default focus: move the cursor into the output (Terminal mode) while
	-- the command runs, so it can read input; back when it exits.
	focus = false,
	-- Dedicated split: fraction of the editor's height (split) or width (vsplit).
	size = 0.3,
	close_on_success = false, -- close the dedicated split when the command exits 0
	-- Shell terminals: keys sent before the command line (Ctrl-U clears
	-- half-typed input), and how long to let the shell recover after
	-- interrupting a still-running previous run (ms).
	clear_line = "\21",
	interrupt_wait = 150,
	-- Name of the shell function typed in shell terminals.
	helper_name = "nrun",
	-- Keep the external window open after the command: "never" | "error" | "always".
	external_hold = "error",
	-- Command prompt: show completions while typing (no <Tab> needed),
	-- fetched in the background this long after the last keystroke (ms).
	live_complete = true,
	live_delay = 120,
}

M.targets = {
	{ id = "vertical", label = "vertical shell (<C-n>)" },
	{ id = "horizontal", label = "horizontal shell (<C-h>n)" },
	{ id = "split", label = "dedicated split (below)" },
	{ id = "vsplit", label = "dedicated vsplit (right)" },
	{ id = "external", label = "external terminal window" },
}

-- OSC sequences between the shell terminals and here (TermRequest):
-- "<tag>;<status>" ends a run, "<tag>-ready" says the helper is defined.
local OSC_TAG = "nvim-runner"

local state -- { [root] = { cmd?, on_save?, target?, cwd? } }
local dedicated = { buf = nil, win = nil, kind = nil } -- the split/vsplit output
local current -- the active run: { kind, job?, buf?, started, label }

local function notify(msg, level)
	vim.notify(msg, level or vim.log.levels.INFO, { title = "runner" })
end

local function load()
	if state then
		return state
	end
	state = {}
	local fd = io.open(M.settings.state_file, "r")
	if fd then
		local ok, data = pcall(vim.json.decode, fd:read("*a"))
		fd:close()
		if ok and type(data) == "table" then
			state = data
		end
	end
	return state
end

local function save()
	vim.fn.mkdir(vim.fs.dirname(M.settings.state_file), "p")
	local fd = io.open(M.settings.state_file, "w")
	if not fd then
		return notify("cannot write " .. M.settings.state_file, vim.log.levels.ERROR)
	end
	fd:write(vim.json.encode(state))
	fd:close()
end

--- Project root of buffer `buf` (default: current).
function M.root(buf)
	return vim.fs.root(buf or 0, M.settings.root_markers) or vim.fn.getcwd()
end

--- Settings of the project of buffer `buf`, defaults filled in (a copy).
---@return { cmd?: string, on_save?: boolean, target: string, cwd: string, focus: boolean }
function M.project(buf)
	local p = vim.deepcopy(load()[M.root(buf)] or {})
	p.target = p.target or M.settings.target
	p.cwd = p.cwd or M.settings.cwd
	if p.focus == nil then
		p.focus = M.settings.focus
	end
	return p
end

local function update(fields, buf)
	local root = M.root(buf)
	load()[root] = vim.tbl_extend("force", state[root] or {}, fields)
	save()
end

--- Where and how a run from buffer `buf` happens: captured before any
--- prompt, so the prompt's own buffer never counts.
local function context(buf)
	buf = buf or vim.api.nvim_get_current_buf()
	local root = M.root(buf)
	local file = vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) or ""
	local mode = M.project(buf).cwd
	local dir = root
	if mode == "file" and file ~= "" then
		dir = vim.fs.dirname(file)
	elseif mode ~= "file" and mode ~= "root" then
		if vim.fn.isdirectory(mode) == 1 then
			dir = mode
		else
			notify(("run folder %s is gone; using the project root"):format(mode), vim.log.levels.WARN)
		end
	end
	return { buf = buf, root = root, dir = dir, file = file }
end

--- Folder the current buffer's project command runs in.
function M.dir()
	return context().dir
end

--- Replace % (with :h filename-modifiers, and %<) by the file, relative to
--- the run folder and quoted for the shell if needed. %% is a literal %.
local function expand(cmd, ctx)
	local rel = ctx.file ~= "" and (vim.fs.relpath(ctx.dir, ctx.file) or ctx.file) or ""
	local out, i = {}, 1
	while i <= #cmd do
		local c = cmd:sub(i, i)
		if c == "%" and cmd:sub(i + 1, i + 1) == "%" then
			out[#out + 1], i = "%", i + 2
		elseif c == "%" then
			local j = i + 1
			while cmd:sub(j, j) == ":" and cmd:sub(j + 1, j + 1):match("[phtre~.8]") do
				j = j + 2
			end
			local mods = cmd:sub(i + 1, j - 1)
			if cmd:sub(j, j) == "<" then
				mods, j = mods .. ":r", j + 1
			end
			local name = vim.fn.fnamemodify(mods:find(":p", 1, true) and ctx.file or rel, mods)
			out[#out + 1], i = shell.quote(name), j
		else
			out[#out + 1], i = c, i + 1
		end
	end
	return table.concat(out)
end

local function finished(run, code)
	if current ~= run then
		return -- a newer run replaced it; its own end is what matters
	end
	current = nil
	local secs = (vim.uv.hrtime() - run.started) / 1e9
	if code == nil then
		return notify(("? %s  (%.1fs, exit status unknown)"):format(run.label, secs))
	end
	local ok = code == 0
	notify(
		("%s %s  (%.1fs%s)"):format(ok and "✓" or "✗", run.label, secs, ok and "" or ", exit " .. code),
		ok and vim.log.levels.INFO or vim.log.levels.ERROR
	)
	if run.on_done then
		run.on_done(ok)
	end
	-- Focus mode: back to where the run started, unless you moved on.
	local back, out = run.return_to, run.out_win
	if back and vim.api.nvim_win_is_valid(back) and vim.api.nvim_get_current_win() == out then
		vim.cmd.stopinsert()
		vim.api.nvim_set_current_win(back)
	end
end

-- Dedicated split / vsplit ------------------------------------------------

local function dedicated_win_shown()
	return dedicated.win
		and vim.api.nvim_win_is_valid(dedicated.win)
		and vim.api.nvim_win_get_tabpage(dedicated.win) == vim.api.nvim_get_current_tabpage()
end

--- Open the dedicated window (current tab) showing `buf`, without moving focus.
local function dedicated_open(buf, kind)
	if dedicated_win_shown() and dedicated.kind == kind then
		vim.api.nvim_win_set_buf(dedicated.win, buf)
		return dedicated.win
	end
	if dedicated_win_shown() then
		vim.api.nvim_win_close(dedicated.win, true) -- other orientation
	end
	local vertical = kind == "vsplit"
	local total = vertical and vim.o.columns or vim.o.lines
	dedicated.win = vim.api.nvim_open_win(buf, false, {
		split = vertical and "right" or "below",
		win = -1, -- relative to the whole editor, not the current window
		[vertical and "width" or "height"] = math.max(1, math.floor(total * M.settings.size)),
	})
	dedicated.kind = kind
	return dedicated.win
end

local function follow(win, buf)
	if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
		vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
	end
end

local function run_dedicated(kind, line, ctx, run)
	local old = dedicated.buf
	local buf = vim.api.nvim_create_buf(false, true)
	local win = dedicated_open(buf, kind)
	if old and old ~= buf and vim.api.nvim_buf_is_valid(old) then
		vim.api.nvim_buf_delete(old, { force = true })
	end
	dedicated.buf = buf
	require("utils.jump").register(buf, function()
		if vim.api.nvim_buf_is_valid(buf) then
			vim.api.nvim_set_current_win(dedicated_open(buf, dedicated.kind or kind))
		end
	end)

	run.on_done = function(ok)
		follow(win, buf)
		if ok and M.settings.close_on_success and dedicated.buf == buf and dedicated_win_shown() then
			vim.api.nvim_win_close(dedicated.win, true)
		end
	end
	vim.api.nvim_buf_call(buf, function()
		run.job = vim.fn.jobstart(shell.argv(line), {
			term = true,
			cwd = ctx.dir,
			on_stdout = function()
				vim.schedule(function()
					follow(win, buf)
				end)
			end,
			on_exit = function(_, code)
				vim.schedule(function()
					finished(run, code)
				end)
			end,
		})
	end)
	return run.job > 0
end

-- Shell terminals (<C-n> / <C-h>n) ------------------------------------------

-- Per shell terminal buffer, from its OSC sequences: the run typed into it
-- and not finished yet, whether the helper is defined, the shell's folder.
local pending, ready, shell_cwd = {}, {}, {}

--- File defining the shell helper (see header). Rewritten when outdated.
function M.helper_file()
	return vim.fs.joinpath(vim.fn.stdpath("state"), "runner", M.settings.helper_name .. ".sh")
end

local function helper_source()
	local n = M.settings.helper_name
	return table.concat({
		"# Written by nvim (utils/runner.lua); edits are overwritten.",
		"# " .. n .. " [-C dir] cmd...  runs cmd in a subshell (in dir), then",
		"# tells nvim its exit status. Source from your shell rc to skip the",
		"# one-time setup line:",
		'#   [ -n "$NVIM" ] && . ' .. shell.path(M.helper_file()),
		n .. "() {",
		'\tif [ "$1" = -C ]; then _' .. n .. "_dir=$2; shift 2; else _" .. n .. "_dir=.; fi",
		'\t(cd -- "$_' .. n .. '_dir" && eval "$*")',
		("\tprintf '\\033]777;%s;%%s\\007' \"$?\""):format(OSC_TAG),
		"}",
		('[ -n "${NVIM:-}" ] && printf \'\\033]777;%s-ready\\007\''):format(OSC_TAG),
		"",
	}, "\n")
end

local function write_helper()
	local path, src = M.helper_file(), helper_source()
	local fd = io.open(path, "r")
	local have = fd and fd:read("*a")
	if fd then
		fd:close()
	end
	if have ~= src then
		vim.fn.mkdir(vim.fs.dirname(path), "p")
		vim.fn.writefile(vim.split(src, "\n", { plain = true }), path)
	end
end

local function decode_url_path(s)
	return (s:gsub("%%(%x%x)", function(h)
		return string.char(tonumber(h, 16))
	end))
end

vim.api.nvim_create_autocmd("TermRequest", {
	group = vim.api.nvim_create_augroup("utils_runner", { clear = true }),
	desc = "Runner: shell terminal reports (run finished, helper ready, folder)",
	callback = function(ev)
		local seq = type(ev.data) == "table" and ev.data.sequence or ev.data
		if type(seq) ~= "string" then
			return
		end
		local buf = ev.buf
		local osc7 = seq:match("^\27%]7;file://[^/]*(/.*)$")
		if osc7 then
			shell_cwd[buf] = decode_url_path(osc7)
			return
		end
		local rest = seq:match("^\27%]777;" .. vim.pesc(OSC_TAG) .. "(.*)$")
		if not rest then
			return
		end
		if rest == "-ready" then
			ready[buf] = true
		elseif rest:match("^;%d+$") and pending[buf] then
			local run = pending[buf]
			pending[buf] = nil
			finished(run, tonumber(rest:sub(2)))
		end
	end,
})
vim.api.nvim_create_autocmd("TermClose", {
	group = "utils_runner",
	desc = "Runner: forget a shell terminal's state",
	callback = function(ev)
		pending[ev.buf], ready[ev.buf], shell_cwd[ev.buf] = nil, nil, nil
	end,
})

--- The line typed into the shell for `line` run in `dir`.
local function shell_line(buf, line, dir)
	if shell.kind() == "fish" then -- no helper for fish: inline, longer
		local inner = ("cd -- %s && %s"):format(vim.fn.shellescape(dir), line)
		return ("sh -c %s; printf '\\033]777;%s;%%s\\007' $status"):format(vim.fn.shellescape(inner), OSC_TAG)
	end
	local parts = {}
	if not ready[buf] then
		write_helper()
		parts[#parts + 1] = ". " .. shell.path(M.helper_file()) .. ";"
		ready[buf] = true -- defined from now on in this shell
	end
	parts[#parts + 1] = M.settings.helper_name
	local here = shell_cwd[buf]
	if here ~= dir then
		local rel = here and vim.fs.relpath(here, dir)
		parts[#parts + 1] = "-C " .. (rel and shell.quote(rel) or shell.path(dir))
	end
	-- Plain words go as they are; anything the shell would act on itself
	-- (operators, quotes, $, globs, ...) is passed as one quoted argument.
	parts[#parts + 1] = line:match("^[%w%-%._/=:+,@%% ]+$") and line or vim.fn.shellescape(line)
	return table.concat(parts, " ")
end

local function run_shell(direction, line, ctx, run)
	local buf = require("utils.terminal").ensure(direction)
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return false
	end
	local chan = vim.bo[buf].channel
	run.buf = buf
	local typed = M.settings.clear_line .. shell_line(buf, line, ctx.dir) .. "\r"
	local busy = pending[buf] ~= nil
	pending[buf] = run
	if busy then
		vim.fn.chansend(chan, "\3")
		vim.defer_fn(function()
			vim.fn.chansend(chan, typed)
		end, M.settings.interrupt_wait)
	else
		vim.fn.chansend(chan, typed)
	end
	-- Keep its window at the end so new output is visible.
	for _, win in ipairs(vim.fn.win_findbuf(buf)) do
		follow(win, buf)
	end
	return true
end

-- External terminal --------------------------------------------------------

local function run_external(line, ctx, run)
	local term = shell.external_terminal()
	if not term then
		notify("no terminal emulator found; set utils.shell settings.external", vim.log.levels.ERROR)
		return false
	end
	local status_file = vim.fn.tempname()
	local script
	if shell.kind() == "fish" then
		local hold = ({ never = "false", always = "true", error = 'test "$s" -ne 0' })[M.settings.external_hold]
			or "false"
		script = table.concat({
			("cd -- %s; or exit"):format(vim.fn.shellescape(ctx.dir)),
			line,
			"set s $status; printf %s $s > " .. vim.fn.shellescape(status_file),
			hold .. '; and begin; printf "\\n[exit %s] Enter closes this window" $s; read _; end',
			"exit $s",
		}, "\n")
	else
		local hold = ({ never = "false", always = "true", error = '[ "$s" -ne 0 ]' })[M.settings.external_hold]
			or "false"
		script = table.concat({
			("cd -- %s || exit"):format(vim.fn.shellescape(ctx.dir)),
			line,
			's=$?; printf %s "$s" > ' .. vim.fn.shellescape(status_file),
			hold .. ' && { printf "\\n[exit %s] Enter closes this window" "$s"; read _; }',
			'exit "$s"',
		}, "\n")
	end
	local argv = vim.list_extend(vim.deepcopy(term), shell.argv(script))
	run.job = vim.fn.jobstart(argv, {
		on_exit = function()
			vim.schedule(function()
				local ok, lines = pcall(vim.fn.readfile, status_file)
				vim.fn.delete(status_file)
				-- No status file: the emulator handed the window to an already
				-- running instance and returned at once.
				finished(run, ok and tonumber(lines[1] or "") or nil)
			end)
		end,
	})
	return run.job > 0
end

-- Public -------------------------------------------------------------------

--- Stop the running command, if any.
function M.stop()
	local run = current
	if not run then
		return
	end
	if run.kind == "shell" then
		if run.buf and vim.api.nvim_buf_is_valid(run.buf) then
			vim.fn.chansend(vim.bo[run.buf].channel, "\3")
		end
		pending[run.buf] = nil
		finished(run, 130) -- what a shell reports for Ctrl-C
	elseif run.job then
		vim.fn.jobstop(run.job)
	end
end

--- Run `cmd` (default: the project's command).
---@param cmd? string
---@param opts? { target?: string, buf?: integer } target: this run only
function M.run(cmd, opts)
	opts = opts or {}
	local ctx = context(opts.buf)
	local project = M.project(ctx.buf)
	cmd = cmd or project.cmd
	if not cmd or cmd == "" then
		return M.set_cmd(true)
	end
	local target = opts.target or project.target
	local line = expand(cmd, ctx)

	if current and current.kind ~= "shell" then
		M.stop() -- shells interrupt their own previous run
	end
	local kind = (target == "vertical" or target == "horizontal") and "shell" or target
	local run = { kind = kind, started = vim.uv.hrtime(), label = line }
	current = run
	local ok
	if kind == "shell" then
		ok = run_shell(target, line, ctx, run)
	elseif kind == "split" or kind == "vsplit" then
		ok = run_dedicated(kind, line, ctx, run)
	elseif kind == "external" then
		ok = run_external(line, ctx, run)
	else
		notify("unknown target " .. tostring(target), vim.log.levels.ERROR)
	end
	if not ok then
		if current == run then
			current = nil
		end
		return notify("could not start " .. line, vim.log.levels.ERROR)
	end

	if project.focus and kind ~= "external" then
		local out = kind == "shell" and vim.fn.win_findbuf(run.buf)[1] or dedicated.win
		local from = vim.api.nvim_get_current_win()
		if out and vim.api.nvim_win_is_valid(out) and out ~= from then
			run.out_win, run.return_to = out, from
			vim.api.nvim_set_current_win(out)
			vim.cmd.startinsert()
		end
	end
end

--- True while a run hasn't finished.
function M.running()
	return current ~= nil
end

--- Show the output of the project's target if hidden, hide it if shown.
function M.toggle_output()
	local target = M.project().target
	if target == "vertical" or target == "horizontal" then
		local term = require("utils.terminal")
		if term.visible(target) then
			term.toggle(target)
		else
			term.ensure(target)
		end
	elseif target == "external" then
		notify("output is in its own window (target: external)")
	elseif dedicated_win_shown() then
		vim.api.nvim_win_close(dedicated.win, true)
	elseif dedicated.buf and vim.api.nvim_buf_is_valid(dedicated.buf) then
		dedicated_open(dedicated.buf, target)
	else
		notify("nothing has run yet")
	end
end

--- Set the project's command.
---@param cmd string
---@param buf? integer
function M.set(cmd, buf)
	update({ cmd = cmd }, buf)
end

--- Set where the project's command runs (an id from M.targets).
function M.set_target(target, buf)
	update({ target = target }, buf)
end

--- Set the project's run folder: "file", "root" or an absolute path.
function M.set_cwd(mode, buf)
	update({ cwd = mode }, buf)
end

--- Toggle focus mode (cursor in the output while the command runs).
function M.toggle_focus()
	local on = not M.project().focus
	update({ focus = on })
	notify(("focus output while running %s for %s"):format(on and "on" or "off", M.root()))
end

--- Toggle running the project's command on <C-S>.
function M.toggle_on_save()
	local on = not M.project().on_save
	update({ on_save = on })
	notify(("run on save %s for %s"):format(on and "on" or "off", M.root()))
end

--- Called by <C-S> after writing: run if this project has run-on-save on.
function M.on_save()
	local p = M.project()
	if p.on_save and p.cmd and p.cmd ~= "" then
		M.run(p.cmd)
	end
end

-- Completion ---------------------------------------------------------------

local complete_dir -- run folder of the buffer a prompt was opened from
local own_complete -- defined below

local function complete_files(lead, dir)
	local typed = lead:gsub("^~/", vim.env.HOME .. "/")
	local absolute = typed:sub(1, 1) == "/"
	local base = absolute and typed or vim.fs.joinpath(dir, typed)
	if typed == "" then
		base = dir .. "/"
	end
	local pattern = vim.fn.escape(base, "*?[]{}\\") .. "*"
	local out = {}
	for _, path in ipairs(vim.fn.glob(pattern, false, true)) do
		local shown = absolute and path or path:sub(#dir + 2)
		if lead:sub(1, 2) == "~/" then
			shown = "~/" .. path:sub(#vim.env.HOME + 2)
		end
		if vim.fn.isdirectory(path) == 1 then
			shown = shown .. "/"
		end
		out[#out + 1] = vim.fn.fnameescape(shown)
	end
	return out
end

--- Completion for shells utils/shell.lua can't ask: programs for the first
--- word (also after ; & | and parens), files relative to `dir` after it.
own_complete = function(upto, lead, dir)
	local before = upto:sub(1, -#lead - 1)
	local command_word = before:match("^%s*$") or before:match("[;&|(]%s*$")
	if command_word and not lead:find("/") then
		return vim.fn.getcompletion(lead, "shellcmd")
	end
	return complete_files(lead, dir)
end

--- Completion for command prompts and :Run: your shell's own completion
--- (utils/shell.lua) in the run folder; for shells it can't ask, programs
--- for the first word (also after ; & | and parens) and files after it.
--- Works in the cmdline and in prompt buffers (snacks.input).
function M.complete(lead)
	local line, col
	if vim.fn.getcmdtype() ~= "" then
		line, col = vim.fn.getcmdline(), vim.fn.getcmdpos() - 1
		if vim.fn.getcmdtype() == ":" then
			local head = line:match("^%s*%a+!?%s+") or ""
			line, col = line:sub(#head + 1), col - #head
		end
	else
		line, col = vim.api.nvim_get_current_line(), vim.api.nvim_win_get_cursor(0)[2]
	end
	local upto = line:sub(1, col)
	local dir = complete_dir or M.dir()
	return shell.complete(upto, dir) or own_complete(upto, lead, dir)
end

M.completion = "customlist,v:lua.require'utils.runner'.complete"

--- In the prompt buffer `buf` (snacks.input), move through suggestions like
--- the LSP completion menu (editor/cmp.lua): <C-j>/<C-k> next/previous
--- (<C-j> also opens them), <CR> accepts the highlighted one. With nothing
--- highlighted <CR> does what the prompt's own <CR> does (submit).
local function menu_keys(buf)
	local own_cr = vim.fn.maparg("<CR>", "i", false, true)
	local function map(lhs, fn, desc)
		vim.keymap.set("i", lhs, fn, { buffer = buf, expr = true, desc = "Run prompt: " .. desc })
	end
	map("<C-j>", function()
		return vim.fn.pumvisible() == 1 and "<C-n>" or "<C-x><C-u>"
	end, "next suggestion")
	map("<C-k>", function()
		return vim.fn.pumvisible() == 1 and "<C-p>" or ""
	end, "previous suggestion")
	map("<CR>", function()
		if vim.fn.pumvisible() == 1 and vim.fn.complete_info({ "selected" }).selected ~= -1 then
			return "<C-y>"
		end
		if own_cr.callback then
			return own_cr.callback() or ""
		end
		return vim.api.nvim_replace_termcodes(own_cr.rhs or "<CR>", true, true, true)
	end, "accept suggestion / submit")
end

--- Suggestions while typing in the prompt buffer `buf` (snacks.input):
--- after each change (debounced), ask in the background and show the
--- matches with complete(), unless the text moved on meanwhile.
local function live_complete(buf, dir)
	if not M.settings.live_complete then
		return
	end
	local timer = assert(vim.uv.new_timer())
	local seq = 0
	local function where()
		if vim.api.nvim_get_current_buf() ~= buf or vim.fn.mode() ~= "i" then
			return nil
		end
		local line, col = vim.api.nvim_get_current_line(), vim.api.nvim_win_get_cursor(0)[2]
		return line, col
	end
	local function suggest()
		local line, col = where()
		if not line then
			return
		end
		local upto = line:sub(1, col)
		local lead = upto:match("%S*$")
		seq = seq + 1
		local mine = seq
		local function show(items)
			local now_line, now_col = where()
			if mine ~= seq or now_line ~= line or now_col ~= col or not items then
				return -- typed on meanwhile, or nothing to show
			end
			items = vim.tbl_filter(function(i)
				return i ~= lead
			end, items)
			if #items > 0 then
				vim.fn.complete(col - #lead + 1, items)
			end
		end
		if not shell.complete_async(upto, dir, show) then
			show(own_complete(upto, lead, dir))
		end
	end
	vim.api.nvim_create_autocmd({ "TextChangedI", "TextChangedP" }, {
		buffer = buf,
		desc = "Runner: live command completion",
		callback = function()
			if vim.fn.pumvisible() == 1 and vim.fn.complete_info({ "selected" }).selected ~= -1 then
				return -- moving through the menu, not typing
			end
			timer:stop()
			timer:start(M.settings.live_delay, 0, vim.schedule_wrap(suggest))
		end,
	})
	vim.api.nvim_create_autocmd({ "BufWipeout", "BufLeave" }, {
		buffer = buf,
		once = true,
		callback = function()
			seq = seq + 1
			if not timer:is_closing() then
				timer:close()
			end
		end,
	})
	-- Suggestions for what's already there (the previous command).
	timer:start(M.settings.live_delay, 0, vim.schedule_wrap(suggest))
end

--- Ask for the project's command (current one pre-filled).
---@param then_run? boolean run it after setting
---@param done? fun() called after the prompt closes (the menu reopens itself)
function M.set_cmd(then_run, done)
	local ctx = context()
	complete_dir = ctx.dir
	shell.prefetch()
	vim.ui.input({
		prompt = ("Run command (in %s): "):format(vim.fn.fnamemodify(ctx.dir, ":~")),
		default = M.project(ctx.buf).cmd or "",
		completion = M.completion,
	}, function(cmd)
		complete_dir = nil
		if cmd then
			M.set(cmd, ctx.buf)
			if then_run and cmd ~= "" then
				M.run(cmd, { buf = ctx.buf })
			end
		end
		if done then
			done()
		end
	end)
	-- snacks.input opens its prompt buffer synchronously (the built-in
	-- input() has returned by now, so nothing to attach to then).
	if vim.bo.filetype == "snacks_input" then
		local buf = vim.api.nvim_get_current_buf()
		menu_keys(buf)
		live_complete(buf, ctx.dir)
	end
end

--- Pick where the project's command runs and remember it; then run it
--- (default) or call `opts.done`.
---@param opts? { done?: fun() }
function M.pick_target(opts)
	opts = opts or {}
	local buf = vim.api.nvim_get_current_buf()
	local now = M.project(buf).target
	vim.ui.select(M.targets, {
		prompt = "Run in",
		format_item = function(t)
			return (t.id == now and "● " or "  ") .. t.label
		end,
	}, function(choice)
		if choice then
			M.set_target(choice.id, buf)
		end
		if opts.done then
			return opts.done()
		elseif choice then
			M.run(nil, { buf = buf })
		end
	end)
end

--- Pick the folder the project's command runs in: the file's folder, the
--- project root, a folder browsed to (utils/browse.lua) or typed.
---@param opts? { done?: fun() } called once the choice is made or cancelled
function M.pick_cwd(opts)
	local done = (opts and opts.done) or function() end
	local ctx = context()
	local buf, now = ctx.buf, M.project(ctx.buf).cwd
	local file_dir = ctx.file ~= "" and vim.fs.dirname(ctx.file) or nil
	local function tilde(p)
		return vim.fn.fnamemodify(p, ":~")
	end
	local choices = {
		{ id = "file", label = "Current file's folder" .. (file_dir and "  " .. tilde(file_dir) or "") },
		{ id = "root", label = "Project root  " .. tilde(ctx.root) },
	}
	if now ~= "file" and now ~= "root" then
		choices[#choices + 1] = { id = now, label = "Chosen folder  " .. tilde(now) }
	end
	vim.list_extend(choices, {
		{ id = "browse", label = "Choose folder…" },
		{ id = "type", label = "Type a path…" },
	})

	local function set(mode)
		if mode then
			M.set_cwd(mode, buf)
			notify("runs in " .. tilde(vim.api.nvim_buf_call(buf, M.dir)))
		end
		done()
	end
	vim.ui.select(choices, {
		prompt = "Run folder",
		format_item = function(c)
			return (c.id == now and "● " or "  ") .. c.label
		end,
	}, function(choice)
		if not choice then
			return done()
		elseif choice.id == "browse" then
			require("utils.browse").browse(ctx.dir, { want = "dir", prompt = "Run folder" }, set)
		elseif choice.id == "type" then
			vim.ui.input({ prompt = "Run folder: ", default = tilde(ctx.dir) .. "/", completion = "dir" }, function(p)
				if not p or vim.trim(p) == "" then
					return done()
				end
				local path = vim.fs.normalize(vim.fn.fnamemodify(vim.fn.expand(vim.trim(p)), ":p"))
				path = path:gsub("/+$", "")
				if vim.fn.isdirectory(path) == 0 then
					notify("not a folder: " .. path, vim.log.levels.WARN)
					return done()
				end
				set(path)
			end)
		else
			set(choice.id)
		end
	end)
end

--- One menu for everything: run, stop, output, and each setting with its
--- current value. Changing a setting reopens the menu; running closes it.
function M.menu()
	local buf = vim.api.nvim_get_current_buf()
	local function reopen()
		vim.schedule(function()
			local win = vim.api.nvim_buf_is_valid(buf) and vim.fn.win_findbuf(buf)[1]
			if win then
				vim.api.nvim_set_current_win(win)
				M.menu()
			end
		end)
	end
	local p = M.project(buf)
	local ctx = context(buf)
	local target_label = p.target
	for _, t in ipairs(M.targets) do
		if t.id == p.target then
			target_label = t.label
		end
	end
	local function onoff(b)
		return b and "on" or "off"
	end
	local items = {
		{ label = "Run now", act = function()
			M.run(nil, { buf = buf })
		end },
		{ label = "Show / hide output", act = M.toggle_output },
		{ label = "Command:       " .. (p.cmd or "(not set)"), act = function()
			M.set_cmd(false, reopen)
		end },
		{ label = "Runs in:       " .. target_label, act = function()
			M.pick_target({ done = reopen })
		end },
		{ label = "Folder:        " .. vim.fn.fnamemodify(ctx.dir, ":~"), act = function()
			M.pick_cwd({ done = reopen })
		end },
		{ label = "Run on <C-S>:  " .. onoff(p.on_save), act = function()
			M.toggle_on_save()
			reopen()
		end },
		{ label = "Focus output:  " .. onoff(p.focus), act = function()
			M.toggle_focus()
			reopen()
		end },
	}
	if M.running() then
		table.insert(items, 2, { label = "Stop the running command", act = M.stop })
	end
	vim.ui.select(items, {
		prompt = "Runner  " .. vim.fn.fnamemodify(ctx.root, ":~"),
		format_item = function(i)
			return i.label
		end,
	}, function(choice)
		if not choice then
			return
		end
		-- Run in the buffer's own window (buf_call would undo a focus switch).
		if vim.api.nvim_get_current_buf() ~= buf then
			local win = vim.fn.win_findbuf(buf)[1]
			if win then
				vim.api.nvim_set_current_win(win)
			end
		end
		choice.act()
	end)
end

return M
