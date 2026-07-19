-- Buffer-local LSP keymaps.
--
-- These are attached on LspAttach rather than set globally: a global `K` map
-- shadows the builtin keywordprg (":help" in Lua, man pages in shell) in every
-- buffer that has no language server.
--
-- Nvim 0.11 already provides these defaults on attach, so they are NOT
-- redefined here:
--   grn -> rename        gra -> code action
--   grr -> references    gri -> implementation
--   K   -> hover         <C-s> (insert) -> signature help

local keymap = require("utils.keybinds")

-- Open an LSP location in a new tab.
local function lsp_jump_in_tab(method)
	return function()
		local clients = vim.lsp.get_clients({ bufnr = 0, method = method })
		if #clients == 0 then
			vim.notify("No LSP client supports " .. method, vim.log.levels.INFO)
			return
		end

		-- 0.11 requires an explicit position_encoding; defaulting to the first
		-- client silently corrupts columns when clangd (utf-8) and pyright
		-- (utf-16) are attached to the same buffer.
		local params = vim.lsp.util.make_position_params(0, clients[1].offset_encoding)

		vim.lsp.buf_request(0, method, params, function(err, result)
			if err or not result or vim.tbl_isempty(result) then
				vim.notify("No location found", vim.log.levels.INFO)
				return
			end

			local location = result[1] or result
			local uri = location.uri or location.targetUri
			local range = location.range or location.targetSelectionRange
			if not uri or not range then
				vim.notify("No location found", vim.log.levels.INFO)
				return
			end

			local bufnr = vim.uri_to_bufnr(uri)
			vim.fn.bufload(bufnr)
			vim.cmd("tabnew")
			vim.api.nvim_set_current_buf(bufnr)
			vim.api.nvim_win_set_cursor(0, { range.start.line + 1, range.start.character })
			vim.cmd("normal! zz")
		end)
	end
end

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
	callback = function(ev)
		local function map(lhs, rhs, desc)
			keymap.map("n", lhs, rhs, { buffer = ev.buf, desc = desc })
		end

		map("gd", vim.lsp.buf.definition, "LSP: go to definition")
		map("gD", vim.lsp.buf.declaration, "LSP: go to declaration")
		map("<leader>f", function()
			vim.lsp.buf.format({ async = true })
		end, "LSP: format")

		map("tgd", lsp_jump_in_tab("textDocument/definition"), "LSP: definition in new tab")
		map("tgD", lsp_jump_in_tab("textDocument/declaration"), "LSP: declaration in new tab")
		map("tgi", lsp_jump_in_tab("textDocument/implementation"), "LSP: implementation in new tab")
		map("tgr", lsp_jump_in_tab("textDocument/references"), "LSP: references in new tab")
	end,
})
