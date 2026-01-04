return function()
    local kb = require("utils.keybinds")
    local rm = require("render-markdown")

    kb.map("n", "<C-R>m", rm.toggle, { silent = true })
end
