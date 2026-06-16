return function()
	local kb = require("utils.keybinds")

	require("jupynium").setup({
		-- python_host = vim.fn.exepath("python3") ~= "" and vim.fn.exepath("python3") or "python",
		-- default_notebook_URL = "localhost:8888",
		-- jupyter_command = "jupyter",
		-- notebook_dir = nil,
		use_default_keybindings = false,
		textobjects = {
			use_default_keybindings = false,
		},
		firefox_profiles_ini_path = vim.fn.expand("~/.mozilla/firefox/profiles.ini"),
		firefox_profile_name = "Jupynium",
	})

	kb.map(
		"n",
		"<space>x",
		"<cmd>JupyniumExecuteSelectedCells<CR>",
		{ silent = true, desc = "Jupynium: Execute cell(s)" }
	)

	-- Start server and attach current buffer
	kb.map(
		"n",
		"<space>jn",
		"<cmd>JupyniumStartAndAttachToServer<CR>",
		{ silent = true, desc = "Jupynium: Start & Attach" }
	)

	-- Start sync for current buffer
	kb.map("n", "<space>js", "<cmd>JupyniumStartSync<CR>", { silent = true, desc = "Jupynium: Start Sync" })

	-- Load from .ipynb tab by index: <space>jl1 .. <space>jl9
	for i = 1, 9 do
		kb.map(
			"n",
			"<space>jl" .. i,
			"<cmd>JupyniumLoadFromIpynbTab " .. i .. "<CR>",
			{ silent = true, desc = "Jupynium: Load from tab " .. i }
		)
	end
end
