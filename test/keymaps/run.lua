-- Headless keymap check: every mapping this config defines must have a
-- description in the form "Area: action", since which-key and the keymap
-- picker (<C-t>k) show it, and it is the only documentation a key gets.
--
--   nvim --headless --cmd "set verbose=1" -c "luafile test/keymaps/run.lua"
--
-- `verbose` must be on from the start: only then does Neovim record which
-- file defined each Lua mapping. Covers global maps from every plugin config
-- (all plugins are loaded first) and lazy `keys` from lua/plugins/lazy/.
-- Buffer-local maps (LSP on attach, netrw) are not covered.

local config_dir = vim.fn.stdpath("config")
local failures, checked = {}, 0

local function finish()
	for _, f in ipairs(failures) do
		print("FAIL  " .. f)
	end
	print(("\n%d mappings checked, %d without a proper description"):format(checked, #failures))
	vim.cmd(#failures == 0 and "qa!" or "cq!")
end

if vim.o.verbose == 0 then
	failures[1] = 'run with --cmd "set verbose=1" (needed to know where mappings come from)'
	return finish()
end

-- Load every plugin so the keymaps in their configs exist.
for _, plugin in ipairs(require("lazy").plugins()) do
	pcall(require("lazy").load, { plugins = { plugin.name } })
end

local function check(where, lhs, mode, desc)
	checked = checked + 1
	if not desc or desc == "" then
		failures[#failures + 1] = ("%s  %s (%s): no description"):format(where, lhs, mode)
	elseif not desc:find("^[^:]+: %S") then
		failures[#failures + 1] = ('%s  %s (%s): "%s" is not "Area: action"'):format(where, lhs, mode, desc)
	end
end

-- Global mappings defined from this config's files.
local seen = {}
for _, mode in ipairs({ "n", "x", "s", "o", "i", "c", "t" }) do
	for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
		local info = map.sid > 0 and vim.fn.getscriptinfo({ sid = map.sid })[1]
		local file = info and info.name or ""
		local key = mode .. map.lhs
		if vim.startswith(file, config_dir) and not seen[key] and not map.lhs:find("^<Plug>") then
			seen[key] = true
			check(vim.fs.relpath(config_dir, file) .. ":" .. map.lnum, map.lhs, mode, map.desc)
		end
	end
end

-- lazy.nvim `keys` from this config's specs (lazy defines those maps itself,
-- so they don't show up as coming from a config file above).
for _, plugin in ipairs(require("lazy").plugins()) do
	for _, key in ipairs(type(plugin.keys) == "table" and plugin.keys or {}) do
		if type(key) == "table" then
			local modes = key.mode or "n"
			check("spec of " .. plugin.name, key[1], type(modes) == "table" and table.concat(modes) or modes, key.desc)
		end
	end
end

finish()
