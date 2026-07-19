-- Terminal keymaps. Toggle logic lives in utils/terminal.lua.
local kb = require("utils.keybinds")
local term = require("utils.terminal")

-- Leave terminal insert mode / close window.
kb.map("t", "<C-X>", "<C-\\><C-n>", { silent = true, desc = "Terminal: to normal mode" })
kb.map("n", "<C-X>", ":x<cr>", { silent = true, desc = "Write and close" })

kb.map({ "n", "t" }, "<C-n>", function()
	term.toggle("vertical")
end, { desc = "Toggle terminal (vertical)" })

kb.map({ "n", "t" }, "<C-h>n", function()
	term.toggle("horizontal")
end, { desc = "Toggle terminal (horizontal)" })
