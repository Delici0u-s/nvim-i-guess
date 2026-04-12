return function()
	local util = require("lspconfig.util") -- util functions are still useful
	local mason_lsp = require("mason-lspconfig")

	-- -- map .mlx -> matlab
	-- if vim.filetype and vim.filetype.add then
	-- 	vim.filetype.add({
	-- 		extension = {
	-- 			mlx = "matlab",
	-- 		},
	-- 	})
	-- end

	-- mason setup (keep your ensure_installed list)
	mason_lsp.setup({
		ensure_installed = {
			"lua_ls",
			"pyright",
			"clangd",
			"jdtls",
			"bashls",
			"jsonls",
			"yamlls",
			"marksman",
			"cmake",
			"mesonlsp",
			"ts_ls",
			"html",
			"cssls",
			"eslint",
			"dockerls",
			"terraformls",
			"asm_lsp",
		},
		automatic_enable = true,
	})

	-- your BufWritePost notifier (unchanged)
	vim.api.nvim_create_autocmd({ "BufWritePost" }, {
		callback = function(args)
			for _, client in ipairs(vim.lsp.get_clients({ bufnr = args.buf })) do
				client:notify("workspace/didChangeWatchedFiles", {
					changes = {
						{
							uri = vim.uri_from_bufnr(args.buf),
							type = 1,
						},
					},
				})
			end
		end,
	})

	vim.lsp.config("asm_lsp", {
		filetypes = { "asm", "nasm", "s", "S" },
		settings = {
			["asm-lsp"] = {
				architecture = "x86_64",
				assembler = "nasm",
			},
		},
	})
end
