local M = {}


function M.content()
	local builtin = require("statuscol.builtin")
	require("statuscol").setup({
	-- configuration goes here, for example:

	relculright = true,

	})
end

return function() M.content() end


