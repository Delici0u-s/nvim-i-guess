-- LSP configuration.
--
-- capabilities MUST be applied before any server is enabled, otherwise servers
-- start without knowing we support snippets (cmp) or folding ranges (ufo).
-- configs/lsp is required before configs/plugins, so this always wins.
require("configs.lsp.capabilities")
require("configs.lsp.diagnostics")
require("configs.lsp.servers")
require("configs.lsp.keymaps")
