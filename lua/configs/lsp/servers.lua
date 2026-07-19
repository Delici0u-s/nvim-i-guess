-- git clone https://github.com/sashi0034/angel-lsp ~/.local/share/angel-lsp
-- cd ~/.local/share/angel-lsp
-- npm install
-- npm run compile

vim.lsp.config("angel_lsp", {
	cmd = { "node", vim.fn.expand("~/.local/share/angel-lsp/server/out/server.js"), "--stdio" },
	filetypes = { "angelscript" },
	root_markers = { "as.predefined", ".git" },
})
vim.lsp.enable("angel_lsp")
vim.filetype.add({
	extension = {
		as = "angelscript",
	},
})
