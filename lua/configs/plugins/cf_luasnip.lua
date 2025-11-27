local ls = require("luasnip")
local kb = require("utils.keybinds")

kb.map({"i"}, "<C-K>", function() ls.expand() end, {silent = true})
kb.map({"i", "s"}, "<C-L>", function() ls.jump( 1) end, {silent = true})
kb.map({"i", "s"}, "<C-J>", function() ls.jump(-1) end, {silent = true})

kb.map({"i", "s"}, "<C-E>", function()
	if ls.choice_active() then
		ls.change_choice(1)
	end
end, {silent = true})


