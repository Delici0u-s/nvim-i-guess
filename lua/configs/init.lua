-- Load order. Each stage may depend on the previous, never the next:
--
--   core    -- options, visual, autocmds, user commands. No plugin requires.
--   theme   -- colourscheme; must precede plugins that define highlights.
--   lsp     -- capabilities/diagnostics/servers/keymaps. MUST precede plugins,
--              since mason enables servers and they need capabilities first.
--   keymaps -- non-plugin keymaps.
--   plugins -- lazy.nvim bootstrap; owns every plugin config from here on.
require("configs.core")
require("configs.theme")
require("configs.lsp")
require("configs.keymaps")
-- require("configs.plugins")
require("plugins.configs")
