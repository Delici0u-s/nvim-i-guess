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

	-- foldingRange capability is advertised in
	-- configs/general/lsp_capabilities.lua, before any server starts. Declaring
	-- it here (on VeryLazy) was too late -- servers had already attached
	-- without it, so the "lsp" fold provider always fell back to treesitter.

	local ufo = require("ufo")

	-- per-buffer fold provider chain: lsp -> treesitter, with fallback
	-- exceptions handled per the official ufo doc/example.lua pattern
	local function customizeSelector(bufnr)
		local function handleFallbackException(err, providerName)
			if type(err) == "string" and err:match("UfoFallbackException") then
				return ufo.getFolds(bufnr, providerName)
			else
				return require("promise").reject(err)
			end
		end

		return ufo.getFolds(bufnr, "lsp"):catch(function(err)
			return handleFallbackException(err, "treesitter")
		end)
	end

	ufo.setup({
		provider_selector = function(_, filetype, buftype)
			if buftype == "nofile" or filetype == "" then
				return ""
			end
			-- return the function reference itself; ufo calls this per
			-- buffer and awaits the Promise it returns
			return customizeSelector
		end,

		close_fold_kinds_for_ft = {
			default = {},
			-- default = { "imports" },
			-- -- doc-comment-heavy languages where collapsing is actually useful
			-- java = { "imports", "comment" },
			-- cpp = { "comment" },
		},
		-- close_fold_kinds_for_ft = {
		-- 	default = { "imports", "comment" },
		-- 	-- default = { "imports", "comment" },
		-- },
		--
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
	-- with your existing configs/lsp/keymaps.lua hover binding.
	kb.map("n", "zk", function()
		local winid = ufo.peekFoldedLinesUnderCursor()
		if not winid then
			vim.lsp.buf.hover()
		end
	end, { desc = "Ufo: peek fold or LSP hover" })
end
