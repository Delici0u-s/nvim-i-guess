return function()
	local kb = require("utils.keybinds")

	-- Required vim options for ufo to work correctly
	vim.o.foldcolumn = "1"
	vim.o.foldlevel = 99
	vim.o.foldlevelstart = 99
	vim.o.foldenable = true

	-- Nicer fold visuals (no eob tilde clutter, clean fold markers)
	vim.opt.fillchars:append({
		eob = " ",
		fold = " ",
		foldsep = " ",
	})

	-- Tell LSP clients we support foldingRange. Since you attach capabilities
	-- globally via cmp_nvim_lsp in cf_cmp.lua, merge this in the same way so
	-- it applies to every server (clangd, pyright, ts_ls, jdtls, zls, ...).
	vim.lsp.config("*", {
		capabilities = {
			textDocument = {
				foldingRange = {
					dynamicRegistration = false,
					lineFoldingOnly = true,
				},
			},
		},
	})

	local ufo = require("ufo")

	ufo.setup({
		-- Try LSP foldingRange first (accurate, server-driven), fall back to
		-- treesitter (covers filetypes without an attached LSP, e.g. zig
		-- before zls attaches, or angelscript), then indent as last resort.
		provider_selector = function(_, filetype, buftype)
			if buftype == "nofile" or filetype == "" then
				return ""
			end
			return { "lsp", "treesitter" }
		end,

		close_fold_kinds_for_ft = {
			default = { "imports", "comment" },
		},

		preview = {
			win_config = {
				border = "rounded",
				winblend = 12,
			},
		},
	})

	-- zR/zM must be remapped per ufo's requirement (manual foldmethod limitation)
	-- kb.map("n", "zR", ufo.openAllFolds, { desc = "Ufo: open all folds" })
	-- kb.map("n", "zM", ufo.closeAllFolds, { desc = "Ufo: close all folds" })
	-- kb.map("n", "zr", ufo.openFoldsExceptKinds, { desc = "Ufo: open folds except kinds" })
	-- kb.map("n", "zm", ufo.closeFoldsWith, { desc = "Ufo: close folds with level" })

	-- Peek the folded content under cursor instead of opening it; falls
	-- back to normal hover if nothing is folded there. Keeps K consistent
	-- with your existing cf_lsp.lua hover binding.
	kb.map("n", "zk", function()
		local winid = ufo.peekFoldedLinesUnderCursor()
		if not winid then
			vim.lsp.buf.hover()
		end
	end, { desc = "Ufo: peek fold or LSP hover" })
end
