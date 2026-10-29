-- claudecode.nvim setup. Loaded by the spec in lua/plugins/lazy/claudecode.lua.
--
--   settings.lua -- every option: fixed ones and the runtime toggles
--   toggles.lua  -- quick-toggle menu (<leader>ao), saved picks, live apply
--   keymaps.lua  -- every Claude key (also the spec's lazy `keys`)
return function()
	require("claudecode").setup(require("plugins.configs.tools.claudecode.toggles").options())
end
