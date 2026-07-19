-- Non-plugin keymaps, grouped by topic. LSP keymaps live in configs/lsp/
-- (they are buffer-local, attached on LspAttach). Plugin keymaps live with
-- their plugin config in configs/plugins/cf_*.lua.
require("configs.keymaps.editor")
require("configs.keymaps.terminal")
require("configs.keymaps.windows")
