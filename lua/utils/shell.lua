-- The user's shell (vim.o.shell, i.e. what nvim was started from unless
-- overridden): running commands through it, quoting, its own <Tab>
-- completion, and the external terminal emulator.
--
-- Used by utils/runner.lua and tools/dap (external terminal). Logic only.

local M = {}

M.settings = {
	-- Run commands with the shell's interactive startup (rc file: aliases,
	-- functions, PATH additions), like typing them at its prompt.
	interactive = true,
	-- External terminal: argv prefix that runs a command in a new window, or
	-- nil to use $TERMINAL (+ "-e") or the first installed candidate.
	external = nil,
	external_candidates = {
		{ "ghostty", "-e" },
		{ "kitty" },
		{ "alacritty", "-e" },
		{ "wezterm", "start", "--" },
		{ "foot" },
		{ "konsole", "-e" },
		{ "gnome-terminal", "--" },
		{ "xterm", "-e" },
	},
	-- Longest wait for the shell's completion of one <Tab> (ms); on timeout
	-- the caller falls back to its own completion.
	complete_timeout = 2000,
	-- zsh completion helper (see its header) and its compinit cache.
	zsh_complete_script = vim.fn.stdpath("config") .. "/scripts/zsh_complete.zsh",
	zsh_compdump = vim.fn.stdpath("cache") .. "/runner-zcompdump",
}

--- Shell family: "zsh" | "bash" | "fish" | "sh" (any other POSIX shell).
function M.kind()
	local name = vim.fs.basename(vim.o.shell):match("^[%w_-]+") or ""
	if name == "zsh" or name == "bash" or name == "fish" then
		return name
	end
	return "sh"
end

--- argv running `script` in the user's shell.
---@param script string in that shell's syntax (POSIX unless kind() == "fish")
function M.argv(script)
	local argv = { vim.o.shell }
	if M.settings.interactive then
		argv[#argv + 1] = "-i"
	end
	vim.list_extend(argv, { "-c", script })
	return argv
end

--- `s` quoted for the shell only when it needs it.
function M.quote(s)
	if s ~= "" and s:match("^[%w%-%._/=:+,@%%]+$") then
		return s
	end
	return vim.fn.shellescape(s)
end

--- A path for the shell: ~ for the home folder, quoted only if needed.
function M.path(p)
	local home = vim.env.HOME
	if home and (p == home or vim.startswith(p, home .. "/")) then
		local rest = p:sub(#home + 2)
		return rest == "" and "~" or "~/" .. M.quote(rest)
	end
	return M.quote(p)
end

--- argv prefix of the external terminal emulator, or nil when none is found.
---@return string[]|nil
function M.external_terminal()
	if M.settings.external then
		return M.settings.external
	end
	if vim.env.TERMINAL and vim.fn.executable(vim.env.TERMINAL) == 1 then
		return { vim.env.TERMINAL, "-e" }
	end
	for _, cand in ipairs(M.settings.external_candidates) do
		if vim.fn.executable(cand[1]) == 1 then
			return cand
		end
	end
end

-- Completion ---------------------------------------------------------------

local zsh_fpath -- the fpath string once known
local probe -- vim.SystemObj while looking it up
local probe_waiters = {} -- callbacks waiting for it (async completion)

local function probe_done(res)
	-- Last non-empty line: rc files may print things before it.
	local lines = vim.split(res and res.stdout or "", "\n", { trimempty = true })
	zsh_fpath = vim.trim(lines[#lines] or "")
	probe = nil
	local waiting = probe_waiters
	probe_waiters = {}
	for _, cb in ipairs(waiting) do
		cb(zsh_fpath)
	end
end

--- Start looking up the interactive zsh's fpath (where its completion
--- functions live, e.g. oh-my-zsh plugins) so the first <Tab> is fast.
function M.prefetch()
	if M.kind() ~= "zsh" or zsh_fpath or probe then
		return
	end
	probe = vim.system({ vim.o.shell, "-ic", "print -r -- ${(j.:.)fpath}" }, { text = true }, function(res)
		vim.schedule(function()
			if probe then
				probe_done(res)
			end
		end)
	end)
end

--- The fpath: now (waiting if needed) or, with `cb`, when known.
local function fpath(cb)
	M.prefetch()
	if zsh_fpath or not probe then
		if cb then
			return cb(zsh_fpath or "")
		end
		return zsh_fpath or ""
	end
	if cb then
		probe_waiters[#probe_waiters + 1] = cb
		return
	end
	probe_done(probe:wait(M.settings.complete_timeout))
	return zsh_fpath
end

--- How to ask this shell: { argv, env, post } or nil when it can't be asked.
local function request(line, dir, fp)
	local kind = M.kind()
	if kind == "zsh" then
		return {
			argv = { vim.o.shell, M.settings.zsh_complete_script, line },
			env = {
				FPATH = fp ~= "" and fp or nil, -- empty would hide zsh's own completions
				ZCOMPDUMP = M.settings.zsh_compdump,
				-- The script stops itself by then; a killed one can leave its
				-- hidden zsh holding the pipe open.
				ZSH_COMPLETE_TIMEOUT = tostring(M.settings.complete_timeout / 1000),
			},
			-- Folders get the "/" zsh's own menu shows (it adds it as a suffix).
			post = function(m)
				if m:sub(-1) == "/" or m:find("$", 1, true) then
					return m -- already marked, or a variable
				end
				local path = m:gsub("\\(.)", "%1"):gsub("^~/", vim.env.HOME .. "/")
				if path:sub(1, 1) ~= "/" then
					path = vim.fs.joinpath(dir, path)
				end
				return vim.fn.isdirectory(path) == 1 and m .. "/" or m
			end,
		}
	elseif kind == "fish" then
		return {
			argv = { vim.o.shell, "-c", "complete -C " .. vim.fn.shellescape(line) },
			post = function(l)
				return (l:gsub("\t.*$", "")) -- drop the description
			end,
		}
	end
end

local function parse(req, res)
	if not res or res.code ~= 0 or res.signal ~= 0 then
		return nil
	end
	return vim.tbl_map(req.post, vim.split(res.stdout or "", "\n", { trimempty = true }))
end

--- Whether this shell's own completion can be asked (zsh, fish).
function M.can_complete()
	return M.kind() == "zsh" or M.kind() == "fish"
end

--- The shell's own completions for the last word of `line`, as if typed at
--- its prompt in `dir` (subcommands, options, variables, files, ...).
--- nil when this shell's completion can't be queried (then use your own).
---@param line string text before the cursor
---@param dir string
---@return string[]|nil
function M.complete(line, dir)
	if not M.can_complete() then
		return nil
	end
	local req = request(line, dir, M.kind() == "zsh" and fpath() or "")
	local ok, obj = pcall(vim.system, req.argv, { cwd = dir, env = req.env, text = true })
	if not ok then
		return nil
	end
	-- Some slack past complete_timeout: the zsh script enforces it itself.
	return parse(req, obj:wait(M.settings.complete_timeout * 2))
end

--- Like M.complete, without blocking: `cb(matches|nil)` runs on the main
--- loop when done. Returns false when this shell can't be asked.
---@param cb fun(matches: string[]|nil)
function M.complete_async(line, dir, cb)
	if not M.can_complete() then
		return false
	end
	fpath(function(fp)
		local req = request(line, dir, M.kind() == "zsh" and fp or "")
		local ok = pcall(vim.system, req.argv, { cwd = dir, env = req.env, text = true }, function(res)
			vim.schedule(function()
				cb(parse(req, res))
			end)
		end)
		if not ok then
			cb(nil)
		end
	end)
	return true
end

return M
