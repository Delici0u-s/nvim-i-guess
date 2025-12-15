local keymap = require("utils.keybinds")

-- Normal LSP keymaps
keymap.map("n", "gd", vim.lsp.buf.definition, { desc = "LSP: go to definition" })
keymap.map("n", "gD", vim.lsp.buf.declaration, { desc = "LSP: go to declaration" })
keymap.map("n", "gr", vim.lsp.buf.references, { desc = "LSP: references" })
keymap.map("n", "gi", vim.lsp.buf.implementation, { desc = "LSP: implementation" })
keymap.map("n", "K", vim.lsp.buf.hover, { desc = "LSP: hover docs" })
keymap.map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "LSP: rename symbol" })
keymap.map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "LSP: code action" })
keymap.map("n", "<leader>f", function()
	vim.lsp.buf.format({ async = true })
end, { desc = "LSP: format" })

local function lsp_jump_in_tab(fn)
	return function()
		local params = vim.lsp.util.make_position_params()
		vim.lsp.buf_request(0, fn, params, function(err, result, ctx, _)
			if err or not result or vim.tbl_isempty(result) then
				vim.notify("No location found", vim.log.levels.INFO)
				return
			end

			-- take the first location (for simplicity)
			local location = result[1]
			local uri = location.uri or location.targetUri
			local range = location.range or location.targetSelectionRange
			local bufnr = vim.uri_to_bufnr(uri)

			-- load buffer
			vim.cmd("tabnew")
			vim.fn.bufload(bufnr)
			vim.api.nvim_set_current_buf(bufnr)

			-- jump to line/column
			local lnum = range.start.line
			local col = range.start.character
			vim.api.nvim_win_set_cursor(0, { lnum + 1, col })
			vim.cmd("normal! zz")
		end)
	end
end

keymap.map("n", "tgd", lsp_jump_in_tab("textDocument/definition"), { desc = "Definition in new tab" })
keymap.map("n", "tgD", lsp_jump_in_tab("textDocument/declaration"), { desc = "Declaration in new tab" })
keymap.map("n", "tgi", lsp_jump_in_tab("textDocument/implementation"), { desc = "Implementation in new tab" })
keymap.map("n", "tgr", lsp_jump_in_tab("textDocument/references"), { desc = "References in new tab" })

return {}
