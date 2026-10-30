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
