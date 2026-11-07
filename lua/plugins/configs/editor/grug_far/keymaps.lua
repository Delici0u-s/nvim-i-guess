-- Search and replace keymaps (grug-far), as a lazy.nvim `keys` list: the spec
-- uses this table directly, so each key both loads grug-far and is mapped by
-- lazy. Add a key here and nowhere else.
--
-- <C-f> works on this file, <C-g> on the whole project ("global"). Both shadow
-- builtins: <C-f> page forward (<C-d> still scrolls), <C-g> file info (lualine
-- shows it) and, in Visual mode, Visual <-> Select. Renaming a code symbol is
-- still LSP `grn`; these are for plain text.
--
-- Inside the grug-far buffer its own keys are buffer-local under <localleader>
-- (\r replace, \s sync edits, \q to quickfix, \c close; g? lists them all).

local function open(options)
	return function()
		require("grug-far").open(options())
	end
end

local function cword()
	return vim.fn.expand("<cword>")
end

return {
	{
		"<C-f>",
		open(function()
			return { prefills = { search = cword(), paths = vim.fn.expand("%") } }
		end),
		desc = "Replace: in this file (word under cursor)",
	},
	{
		"<C-f>",
		open(function()
			return { visualSelectionUsage = "operate-within-range" }
		end),
		mode = "x",
		desc = "Replace: within the selection",
	},
	{
		"<C-g>",
		open(function()
			return { prefills = { search = cword() } }
		end),
		desc = "Replace: in project (word under cursor)",
	},
	{
		"<C-g>",
		open(function()
			return { visualSelectionUsage = "prefill-search" }
		end),
		mode = "x",
		desc = "Replace: in project (selected text)",
	},
}
