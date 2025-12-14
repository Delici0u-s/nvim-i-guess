-- Create a :VT command for vertical terminal
vim.api.nvim_create_user_command("VT", function()
	vim.cmd("vsplit") -- vertical split
	vim.cmd("terminal") -- open terminal in the new split
end, {})
