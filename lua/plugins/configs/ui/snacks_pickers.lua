-- Tweaked snacks pickers for looking things up (<C-t>k keymaps, <C-t>c commands).
--
-- Keymaps: snacks' default row is mode, key, rhs ("callback" for every Lua
-- function, padded wide), then the description, so the description ended up
-- under the preview. Here the description comes right after the key, and the
-- rhs only follows when it is a real string (e.g. "<cmd>Hex<CR>"). Built-in
-- keys (dd, ciw, <C-w>v, ...) are listed too, tagged "builtin".
--
-- Commands: snacks matches only the command name. The description is added
-- to the searchable text so you can find a command by what it does.
local M = {}

-- Help index ----------------------------------------------------------------
--
-- Built-in keys and Ex commands aren't mappings, so nothing lists them, but
-- Neovim's doc/index.txt has every one with a one-line summary, in tables like
--   |i_CTRL-W|	CTRL-W		delete word before the cursor
--   |dd|		["x]dd		2  delete N lines [into register x]
-- grouped in sections ("2.2 Window commands	*CTRL-W*"). Read once, on first use.

-- First tag of a section header -> mode of that section's keys ("ex" = Ex commands).
local index_sections = {
	["insert-index"] = "i",
	["normal-index"] = "n",
	objects = "o", -- text objects; also work in Visual mode
	["CTRL-W"] = "n",
	["["] = "n",
	g = "n",
	z = "n",
	["operator-pending-index"] = "o",
	["visual-index"] = "v",
	["ex-edit-index"] = "c",
	["terminal-mode-index"] = "t",
	["Ex-commands"] = "ex",
}

--- "CTRL-W CTRL-F" -> "<C-W><C-F>", "CTRL-G j" -> "<C-G>j"; other notation kept.
local function to_lhs(key)
	key = key:gsub("CTRL%-<(%w+)>", "<C-%1>"):gsub("CTRL%-(%S)", "<C-%1>"):gsub(" ", "")
	return Snacks.util.normkey(key)
end

local help_index

---@return { file: string?, keys: table[], commands: table<string, string> }
function M.help_index()
	if help_index then
		return help_index
	end
	local file = vim.api.nvim_get_runtime_file("doc/index.txt", false)[1]
	help_index = { file = file, keys = {}, commands = {} }
	local mode, last
	for lnum, line in ipairs(file and vim.fn.readfile(file) or {}) do
		local section = line:match("^%d[%.%d]*%s.-%*([^%*]+)%*")
		if section then
			mode, last = index_sections[section], nil
		elseif mode == "ex" then
			local name, desc = line:match("^|:([^|]+)|\t+%S+\t+(.+)$")
			if name then
				help_index.commands[name] = desc
			end
		elseif mode then
			local tag, key, rest = line:match("^|([^|]+)|\t+([^\t]+)\t*(.*)$")
			if tag then
				-- A few rows separate key and text with a space, not a tab
				-- ("CTRL-\ e {expr} replace the ..."): split at the first word.
				local k, spill = key:match("^(.-%S)%s+(%l%l%l+.*)$")
				if k then
					key, rest = k, spill .. " " .. rest
				end
				-- Drop the optional note number ("1"/"2" before the text).
				local desc = vim.trim(rest):gsub("^[12]%s+", "")
				last = { mode = mode, tag = tag, lhs = to_lhs(key), desc = desc, lnum = lnum }
				help_index.keys[#help_index.keys + 1] = last
			elseif last and line:find("^\t\t\t") then
				-- Continuation of the previous description.
				last.desc = vim.trim(last.desc .. " " .. vim.trim(line))
			else
				last = nil -- untagged row ("not used") or prose
			end
		end
	end
	return help_index
end

-- Keymaps -------------------------------------------------------------------

-- Mapping modes that cover each built-in key's mode (" " = :map, i.e. n+v+o).
local covers =
	{ n = { "n", " " }, v = { "v", "x", " " }, o = { "o", " " }, i = { "i", "!" }, c = { "c", "!" }, t = { "t" } }

--- snacks' keymap finder plus the built-in keys, with column widths taken
--- from the content so the format can align on them.
local function keymap_finder(opts, ctx)
	local items = require("snacks.picker.source.vim").keymaps(opts, ctx)

	local mapped = {} -- mode .. lhs of every mapping, to flag overridden built-ins
	for _, item in ipairs(items) do
		local lhs = Snacks.util.normkey(item.item.lhs)
		mapped[item.item.mode .. lhs] = true
		item.tag = (item.item.buffer or 0) > 0 and "buf" or ""
	end

	if opts.builtin then
		local index = M.help_index()
		for _, key in ipairs(index.keys) do
			local plain = key.lhs:gsub('^%["x%]', "") -- register prefix isn't part of the key
			local overridden = vim.iter(covers[key.mode] or {}):any(function(m)
				return mapped[m .. plain]
			end)
			items[#items + 1] = {
				builtin = true,
				tag = "builtin",
				help = key.tag,
				overridden = overridden,
				item = { mode = key.mode, lhs = key.lhs, desc = key.desc },
				text = key.lhs .. " builtin " .. key.desc,
				file = index.file,
				pos = { key.lnum, 0 },
				preview = "file",
			}
		end
	end

	local lhs_width, tag_width = 0, 0
	for _, item in ipairs(items) do
		lhs_width = math.max(lhs_width, vim.api.nvim_strwidth(Snacks.util.normkey(item.item.lhs)))
		tag_width = math.max(tag_width, #item.tag)
	end
	for _, item in ipairs(items) do
		item.lhs_width, item.tag_width = lhs_width, tag_width
	end
	return items
end

local function keymap_format(item)
	local k = item.item
	local align = Snacks.picker.util.align
	local ret = {
		{ k.mode, "SnacksPickerKeymapMode" },
		{ " " },
		{ align(Snacks.util.normkey(k.lhs), item.lhs_width), "SnacksPickerKeymapLhs" },
		{ " " },
	}
	if item.tag_width > 0 then
		ret[#ret + 1] =
			{ align(item.tag, item.tag_width), item.builtin and "SnacksPickerSpecial" or "SnacksPickerBufNr" }
		ret[#ret + 1] = { " " }
	end
	ret[#ret + 1] = { k.desc or "" }
	if item.overridden then
		-- A mapping (yours, a plugin's or Neovim's default) changes this key;
		-- its own row in the list says what it does now.
		ret[#ret + 1] = { "  (remapped)", "WarningMsg" }
	elseif k.rhs and k.rhs ~= "" then
		ret[#ret + 1] = { "  " .. k.rhs, "NonText" }
	end
	return ret
end

local function open_help(picker, item)
	picker:close()
	vim.cmd.help(item.help)
end

function M.keymaps()
	return Snacks.picker.keymaps({
		finder = keymap_finder,
		format = keymap_format,
		builtin = true, -- list built-in keys too; <A-b> toggles
		-- <CR> runs a mapping, or opens the help for a built-in key (most need
		-- a motion or count, so running them from here means little).
		confirm = function(picker, item)
			if not item then
				return
			end
			if item.builtin then
				return open_help(picker, item)
			end
			picker:norm(function()
				picker:close()
				vim.api.nvim_input(item.item.lhs)
			end)
		end,
		actions = {
			-- Where a mapping is defined (known for Lua-function maps, which
			-- is nearly all of this config's); the help for a built-in.
			definition = function(picker, item)
				if item and item.builtin then
					return open_help(picker, item)
				end
				picker:action("jump")
			end,
			toggle_builtin = function(picker)
				picker.opts.builtin = not picker.opts.builtin
				picker:find()
			end,
		},
		win = {
			input = {
				keys = {
					["<a-g>"] = { "definition", mode = { "n", "i" } },
					["<a-b>"] = { "toggle_builtin", mode = { "n", "i" } },
				},
			},
			list = { keys = { ["<a-g>"] = "definition", ["<a-b>"] = "toggle_builtin" } },
		},
	})
end

-- Commands ------------------------------------------------------------------

function M.commands()
	local builtins = M.help_index().commands
	return Snacks.picker.commands({
		transform = function(item)
			-- snacks only keeps a description for some Lua commands. A user
			-- command's `definition` is its desc (Lua) or its replacement text
			-- (Vimscript); built-ins (snacks marks them "completion") get the
			-- summary from the help index.
			local def = item.command and item.command.definition
			if not item.desc and def == "completion" then
				item.desc = builtins[item.cmd]
			elseif not item.desc and def and def ~= "" then
				item.desc = def
			end
			if item.desc then
				item.text = item.cmd .. " " .. item.desc
			end
			return item
		end,
	})
end

return M
