-- Global LSP capabilities.
--
-- This MUST run before mason-lspconfig enables any server, otherwise servers
-- start with default capabilities and never learn that we support snippet
-- completion (cmp) or folding ranges (ufo). configs/general is loaded before
-- configs/plugins, so this file always wins the race.
--
-- cmp-nvim-lsp is declared `lazy = false` in lua/plugins/general.lua purely so
-- that it is requireable here; it is a small table-returning module with no
-- runtime cost of its own.

local caps = vim.lsp.protocol.make_client_capabilities()

-- nvim-ufo: advertise foldingRange so the "lsp" fold provider works.
caps.textDocument.foldingRange = {
	dynamicRegistration = false,
	lineFoldingOnly = true,
}

-- nvim-cmp: snippet/resolve support. Optional -- if cmp-nvim-lsp is missing we
-- still get a working (if less capable) client rather than an error at startup.
local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
if ok then
	caps = vim.tbl_deep_extend("force", caps, cmp_lsp.default_capabilities())
end

vim.lsp.config("*", { capabilities = caps })
