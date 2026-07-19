return function()
	local kb = require("utils.keybinds")
	local rm = require("render-markdown")

	local opts = {}
	-- local opts = { file_types = { "markdown", "python" } }
	rm.setup(opts)

	kb.map("n", "<C-R>m", rm.toggle, { silent = true })
end
