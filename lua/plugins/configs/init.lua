-- Bootstrap lazy.nvim.
--
-- Configs are grouped by domain: ui/ editor/ lang/ tools/. Each returns a
-- function and is required only from its spec in lua/plugins/ -- never by
-- globbing this folder, which used to run plugin configs before their plugins
-- existed on the runtimepath.
require("plugins.configs.lazy")
