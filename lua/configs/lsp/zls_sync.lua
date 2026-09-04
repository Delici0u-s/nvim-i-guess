local M = {}

local script_path = vim.fs.joinpath(vim.fn.stdpath("config"), "scripts", "zls_sync.py")

-- Cache the result for the lifetime of this Neovim session so repeated
-- calls don't re-spawn a process.
local cached_path = nil
local checked = false

local function is_python3(exe)
	local ok, result = pcall(function()
		return vim.system({ exe, "--version" }, { text = true }):wait(3000)
	end)
	if not ok or not result or result.code ~= 0 then
		return false
	end
	local out = (result.stdout or "") .. (result.stderr or "")
	return out:match("Python%s+3%.") ~= nil
end

local function find_python()
	for _, exe in ipairs({ "python3", "python", "py" }) do
		if vim.fn.executable(exe) == 1 and is_python3(exe) then
			return exe
		end
	end
	return nil
end

--- Synchronously resolves a zls binary matching the installed zig version.
--- Returns nil (letting lspconfig fall back to PATH/mason's zls) if zig,
--- a Python 3 interpreter, or the sync script itself aren't available, or
--- the sync fails or times out.
---
--- NOTE: `SystemObj:wait(timeout)`'s exact behavior on timeout (whether it
--- returns nil vs. a result describing a killed process) isn't something
--- I've verified against your Neovim build, so this checks for both.
function M.get_zls_path()
	if checked then
		return cached_path
	end
	checked = true

	if vim.fn.executable("zig") == 0 then
		return nil
	end
	if vim.fn.filereadable(script_path) == 0 then
		vim.notify("zls_sync: script not found at " .. script_path, vim.log.levels.WARN)
		return nil
	end
	local python = find_python()
	if not python then
		vim.notify("zls_sync: no Python 3 interpreter on PATH, skipping zls auto-sync", vim.log.levels.WARN)
		return nil
	end

	local result = vim.system({ python, script_path }, { text = true }):wait(20000)
	if not result then
		vim.notify("zls_sync: timed out waiting for sync", vim.log.levels.WARN)
		return nil
	end
	if result.code ~= 0 or (result.signal and result.signal ~= 0) then
		local reason = (result.signal and result.signal ~= 0)
				and ("killed (signal " .. result.signal .. "), possibly timed out")
			or vim.trim(result.stderr or "sync failed")
		vim.notify("zls_sync: " .. reason, vim.log.levels.WARN)
		return nil
	end

	local path = vim.trim(result.stdout or "")
	cached_path = path ~= "" and path or nil
	return cached_path
end

return M
