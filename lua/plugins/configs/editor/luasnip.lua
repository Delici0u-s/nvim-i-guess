return function()
	local ls = require("luasnip")

	-- Load the snippet definitions in editor/snippets/.
	require("plugins.configs.editor.snippets")

	-- <Tab> only steals the key when a snippet is actually active; otherwise it
	-- falls through so nvim-cmp and normal indentation still work.
	vim.keymap.set({ "i", "s" }, "<Tab>", function()
		if ls.expand_or_jumpable() then
			ls.expand_or_jump()
		else
			return "<Tab>"
		end
	end, { expr = true, desc = "LuaSnip: expand or jump forward" })

	vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
		if ls.jumpable(-1) then
			ls.jump(-1)
		else
			return "<S-Tab>"
		end
	end, { expr = true, desc = "LuaSnip: jump backward" })

	-- Stop the jump-back chain once the cursor leaves the snippet region,
	-- otherwise stale snippet sessions keep capturing <Tab>.
	vim.api.nvim_create_autocmd("ModeChanged", {
		group = vim.api.nvim_create_augroup("luasnip_unlink", { clear = true }),
		pattern = { "s:n", "i:*" },
		callback = function()
			if
				ls.session
				and ls.session.current_nodes[vim.api.nvim_get_current_buf()]
				and not ls.session.jump_active
			then
				ls.unlink_current()
			end
		end,
	})
end
