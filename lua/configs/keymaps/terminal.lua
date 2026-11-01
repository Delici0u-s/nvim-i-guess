-- Terminal keymaps. Toggle logic lives in utils/terminal.lua.
local kb = require("utils.keybinds")
local term = require("utils.terminal")

-- Leave terminal insert mode / close window.
kb.map("t", "<C-X>", "<C-\\><C-n>", { silent = true, desc = "Terminal: to normal mode" })
kb.map("n", "<C-X>", ":x<cr>", { silent = true, desc = "Editor: write and close" })

kb.map({ "n", "t" }, "<C-n>", function()
	term.toggle("vertical")
end, { desc = "Terminal: toggle (vertical)" })

kb.map({ "n", "t" }, "<C-h>n", function()
	term.toggle("horizontal")
end, { desc = "Terminal: toggle (horizontal)" })

-- <A-e> jumps between the editor and the terminal used last (shell or
-- Claude), back to the window you came from. Logic in utils/jump.lua.
local jump = require("utils.jump")
jump.setup()
kb.map({ "n", "i", "t" }, "<A-e>", jump.toggle, { desc = "Terminal: jump between editor and terminal" })

-- Project runner (utils/runner.lua): one command per project, run in a
-- shell terminal, a dedicated split or an external window while you stay
-- where you are.
local runner = require("utils.runner")
-- Actions: r run, o output, k stop; S the menu with everything.
kb.map("n", "<leader>rr", function()
	runner.run()
end, { desc = "Run: project command" })
kb.map("n", "<leader>ro", runner.toggle_output, { desc = "Run: show/hide output" })
kb.map("n", "<leader>rk", runner.stop, { desc = "Run: stop" })
kb.map("n", "<leader>rS", runner.menu, { desc = "Run: menu (run, stop, all settings)" })
-- Quick settings under <leader>rs.
kb.map("n", "<leader>rc", function()
	runner.set_cmd(false)
end, { desc = "Run: set project command" })
kb.map("n", "<leader>rsc", function()
	runner.set_cmd(false)
end, { desc = "Run: set project command" })
kb.map("n", "<leader>rst", runner.pick_target, { desc = "Run: pick where it runs (and run)" })
kb.map("n", "<leader>rsd", runner.pick_cwd, { desc = "Run: pick the folder it runs in" })
kb.map("n", "<leader>rss", runner.toggle_on_save, { desc = "Run: toggle run on <C-S>" })
kb.map("n", "<leader>rsf", runner.toggle_focus, { desc = "Run: toggle focus output while running" })

vim.api.nvim_create_user_command("Run", function(opts)
	if opts.args ~= "" then
		runner.set(opts.args)
	end
	runner.run()
end, { nargs = "*", complete = runner.completion, desc = "Run the project command (args: set it first)" })
