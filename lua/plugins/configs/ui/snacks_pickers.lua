-- Tweaked snacks pickers for looking things up (<C-t>k keymaps, <C-t>c commands).
--
-- Keymaps: snacks' default row is mode, key, rhs ("callback" for every Lua
-- function, padded wide), then the description, so the description ended up
-- under the preview. Here the description comes right after the key, and the
-- rhs only follows when it is a real string (e.g. "<cmd>Hex<CR>").
--
-- Commands: snacks matches only the command name. The description is added
-- to the searchable text so you can find a command by what it does.
local M = {}

-- Keymaps -------------------------------------------------------------------

--- snacks' keymap finder, plus the widest key so the format can align on it.
local function keymap_finder(opts, ctx)
	local items = require("snacks.picker.source.vim").keymaps(opts, ctx)
	local width = 0
	for _, item in ipairs(items) do
		width = math.max(width, vim.api.nvim_strwidth(Snacks.util.normkey(item.item.lhs)))
	end
	for _, item in ipairs(items) do
		item.lhs_width = width
	end
	return items
end

local function keymap_format(item)
	local k = item.item
	local ret = {
		{ k.mode, "SnacksPickerKeymapMode" },
		{ " " },
		{ Snacks.picker.util.align(Snacks.util.normkey(k.lhs), item.lhs_width), "SnacksPickerKeymapLhs" },
		{ " " },
	}
	if k.buffer and k.buffer > 0 then
		ret[#ret + 1] = { "buf ", "SnacksPickerBufNr" }
	end
	ret[#ret + 1] = { k.desc or "" }
	if k.rhs and k.rhs ~= "" then
		ret[#ret + 1] = { "  " .. k.rhs, "NonText" }
	end
	return ret
end

function M.keymaps()
	return Snacks.picker.keymaps({
		finder = keymap_finder,
		format = keymap_format,
		-- <CR> runs the key (snacks default); <A-g> opens where it is defined
		-- (known for Lua-function maps, which is nearly all of this config's).
		win = {
			input = { keys = { ["<a-g>"] = { "jump", mode = { "n", "i" } } } },
			list = { keys = { ["<a-g>"] = "jump" } },
		},
	})
end

-- Commands ------------------------------------------------------------------

local builtin_desc -- name -> one-line summary, read once from the help

--- Summaries of built-in Ex commands from :help ex-cmd-index (index.txt),
--- lines like "|:edit|		:e[dit]		edit a file".
local function builtin_descriptions()
	if builtin_desc then
		return builtin_desc
	end
	builtin_desc = {}
	local index = vim.api.nvim_get_runtime_file("doc/index.txt", false)[1]
	for _, line in ipairs(index and vim.fn.readfile(index) or {}) do
		local name, desc = line:match("^|:([^|]+)|\t+%S+\t+(.+)$")
		if name then
			builtin_desc[name] = desc
		end
	end
	return builtin_desc
end

function M.commands()
	local builtins = builtin_descriptions()
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
