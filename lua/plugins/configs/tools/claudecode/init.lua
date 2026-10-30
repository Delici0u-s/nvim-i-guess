-- claudecode.nvim setup. Loaded by the spec in lua/plugins/lazy/claudecode.lua.
--
--   settings.lua -- every option: fixed ones and the runtime toggles
--   toggles.lua  -- quick-toggle menu (<leader>ao), saved picks, live apply
--   keymaps.lua  -- every Claude key (also the spec's lazy `keys`)
--   diffs.lua    -- accept/reject/jump to diffs from any window
--   terminal.lua -- keys inside the Claude terminal (<C-x> chords)
--   picker.lua   -- snacks picker action "add to Claude" (<A-c>, ui/snacks.lua)
return function()
	require("claudecode").setup(require("plugins.configs.tools.claudecode.toggles").options())
	require("plugins.configs.tools.claudecode.terminal").setup()
	require("plugins.configs.tools.claudecode.diffs").setup()
end
