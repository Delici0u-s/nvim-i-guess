-- Launch-configuration helpers.
--
-- mason-nvim-dap's default configurations ask for the program path and the
-- arguments with blocking vim.fn.input prompts. improve() swaps those for a
-- picker and vim.ui.input. It is applied to every adapter's defaults, so an
-- adapter added later gets the same behaviour without per-language code.
--
-- nvim-dap evaluates function-valued configuration fields inside a coroutine,
-- so the helpers yield while the picker/input is open instead of blocking.

local settings = require("plugins.configs.tools.dap.settings")

local M = {}

local function in_coroutine()
	local co, is_main = coroutine.running()
	return co ~= nil and not is_main
end

--- vim.ui.input that waits for the answer. Returns nil if cancelled.
local function input(opts)
	if not in_coroutine() then
		return vim.fn.input(opts) -- accepts prompt/default/completion too
	end
	local co = coroutine.running()
	vim.ui.input(opts, function(answer)
		vim.schedule(function()
			coroutine.resume(co, answer)
		end)
	end)
	return coroutine.yield()
end

-- A file starting with "#!" is a script, not a build output.
local function is_script(path)
	local fd = io.open(path, "rb")
	if not fd then
		return true
	end
	local head = fd:read(2)
	fd:close()
	return head == "#!"
end

local user_execute = tonumber("100", 8)

--- An executable file that is not a script (i.e. something a native debugger can run).
local function is_program(path, stat)
	stat = stat or vim.uv.fs_stat(path)
	return stat ~= nil and stat.type == "file" and bit.band(stat.mode, user_execute) ~= 0 and not is_script(path)
end

--- Executable, non-script files under `root`, most recently built first.
---@return string[]
function M.executables(root)
	local found = {}
	local skip = settings.picker_skip_dirs
	for name, type in
		vim.fs.dir(root, {
			depth = math.huge,
			-- `skip` returns false to *not* descend into a directory.
			skip = function(dir)
				local base = vim.fs.basename(dir)
				return base:sub(1, 1) ~= "." and not vim.tbl_contains(skip, base)
			end,
		})
	do
		if type == "file" then
			local path = vim.fs.joinpath(root, name)
			local stat = vim.uv.fs_stat(path)
			if is_program(path, stat) then
				found[#found + 1] = { path = path, mtime = stat.mtime.sec }
			end
		end
	end
	table.sort(found, function(a, b)
		return a.mtime > b.mtime
	end)
	return vim.tbl_map(function(f)
		return f.path
	end, found)
end

-- Picker entries for programs get the `ls -F` executable suffix; the rest
-- of the labels and the browser come from utils/browse.lua.
local browser = require("utils.browse")
local kinds = { file = { suffix = "*", hl = "Function" } }

--- dap's coroutine-aware vim.ui.select (inputlist outside a coroutine);
--- waits for the answer, so it also drives utils/browse synchronously.
local function select(items, opts, cb)
	local ui = require("dap.ui")
	cb((in_coroutine() and ui.pick_one or ui.pick_one_sync)(items, opts.prompt, opts.format_item))
end

local function pick(entries, prompt)
	local chosen
	select(entries, {
		prompt = prompt,
		format_item = function(e, chunks)
			return browser.format(e, chunks, kinds)
		end,
	}, function(e)
		chosen = e
	end)
	return chosen
end

--- One directory level for the browser: "../", subdirectories (hidden ones
--- last), then programs.
function M.list_dir(dir)
	return browser.list(dir, is_program)
end

--- Browse for a program like netrw: pick a directory to enter it ("../" goes
--- up), pick a program to choose it. Returns nil if cancelled.
local function browse(dir)
	local chosen
	browser.browse(dir, { files = is_program, kinds = kinds, select = select }, function(path)
		chosen = path
	end)
	return chosen
end

--- Type the program path (with file completion).
local function type_program(root)
	local answer = input({ prompt = "Program to debug: ", default = root .. "/", completion = "file" })
	if answer == nil or vim.trim(answer) == "" then
		return nil
	end
	return vim.fn.fnamemodify(vim.fn.expand(vim.trim(answer)), ":p")
end

local last_program -- offered first next time, while it is under the cwd

--- Pick the program to debug. Lists the executables under the cwd (last pick
--- first, then newest), followed by "Browse…" and "Type a path…". With no
--- executables under the cwd it opens the browser directly.
function M.pick_program()
	local dap = require("dap")
	local root = vim.fn.getcwd()
	local programs = M.executables(root)
	if last_program and vim.fs.relpath(root, last_program) and vim.fn.executable(last_program) == 1 then
		programs = vim.tbl_filter(function(p)
			return p ~= last_program
		end, programs)
		table.insert(programs, 1, last_program)
	end
	-- The browser starts where the last pick was, else in the cwd.
	local browse_from = last_program and vim.fs.dirname(last_program) or root

	local chosen
	if #programs == 0 then
		chosen = browse(browse_from)
	else
		local entries = vim.tbl_map(function(path)
			return { path = path, name = vim.fs.relpath(root, path) or path, kind = "file" }
		end, programs)
		vim.list_extend(entries, {
			{ action = browse, name = "Browse…", kind = "action" },
			{ action = type_program, name = "Type a path…", kind = "action" },
		})
		local entry = pick(entries, "Program to debug: ")
		if entry and entry.action then
			chosen = entry.action(entry.action == browse and browse_from or root)
		else
			chosen = entry and entry.path
		end
	end

	if not chosen then
		return dap.ABORT
	end
	if vim.fn.executable(chosen) == 0 then
		vim.notify("Debug: not an executable: " .. chosen, vim.log.levels.WARN)
		return dap.ABORT
	end
	last_program = chosen
	return chosen
end

local last_args = ""

--- Ask for program arguments (shell-like quoting), remembering the last answer.
function M.ask_args()
	local answer = input({ prompt = "Arguments: ", default = last_args })
	if answer == nil then
		return require("dap").ABORT
	end
	last_args = answer
	return require("dap.utils").splitstr(answer)
end

--- The project's Python: active venv/conda env, else a venv directory found
--- upwards from the current file, else python3 from PATH.
function M.python_path()
	local env = os.getenv("VIRTUAL_ENV") or os.getenv("CONDA_PREFIX")
	if env then
		return vim.fs.joinpath(env, "bin", "python")
	end
	local file = vim.api.nvim_buf_get_name(0)
	local root = vim.fs.root(file ~= "" and file or vim.fn.getcwd(), settings.venv_dirs)
	if root then
		for _, dir in ipairs(settings.venv_dirs) do
			local python = vim.fs.joinpath(root, dir, "bin", "python")
			if vim.fn.executable(python) == 1 then
				return python
			end
		end
	end
	return vim.fn.exepath("python3")
end

--- Adds an "(args)" copy of each launch configuration when an adapter's
--- defaults have no way to pass arguments (e.g. debugpy's single "Launch
--- file"). Adapters that already offer one (codelldb) are left as they are.
function M.with_args_variants(configs)
	local has_args = vim.iter(configs):any(function(c)
		return c.request == "launch" and type(c.args) == "function"
	end)
	if has_args then
		return configs
	end
	local out = {}
	for _, c in ipairs(configs) do
		out[#out + 1] = c
		if c.request == "launch" then
			local variant = vim.deepcopy(c)
			variant.name = c.name .. " (args)"
			variant.args = M.ask_args
			out[#out + 1] = variant
		end
	end
	return out
end

--- Copy of a configuration with the blocking prompts replaced.
function M.improve(config)
	config = vim.deepcopy(config)
	if config.request == "launch" then
		if type(config.program) == "function" then
			config.program = M.pick_program
		end
		if type(config.args) == "function" then
			config.args = M.ask_args
		end
	end
	return config
end

return M
