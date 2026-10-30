local M = {}

function M.map(mode, lhs, rhs, opts)
	local options = { noremap = true }
	if opts then
		options = vim.tbl_extend("force", options, opts)
	end

	-- If rhs is a function (or mode is a table), use the newer API that accepts functions/tables.
	if type(rhs) == "function" or type(mode) == "table" then
		-- vim.keymap.set accepts mode as string or table and rhs as function or string.
		return vim.keymap.set(mode, lhs, rhs, options)
	end

	-- otherwise use the classical API (string rhs)
	-- Both calls are tail calls on purpose: that drops this function's stack
	-- frame, so Neovim records the *caller's* file and line as where the map was
	-- defined (shown by :verbose map and the <C-t>k keymap picker).
	return vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

return M
