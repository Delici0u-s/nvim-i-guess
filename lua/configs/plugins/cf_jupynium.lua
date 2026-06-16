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
		notebook_dir = vim.fn.expand("~/notebooks"),
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
	kb.map("n", "<space>js", function()
		local file = vim.fn.expand("nvim_jupynotebook.ipynb")
		if vim.fn.filereadable(file) == 1 then
			vim.fn.delete(file)
		end
		vim.cmd("JupyniumStartSync nvim_jupynotebook")
	end, { silent = true, desc = "Jupynium: Start Sync" })
	-- kb.map(
	-- 	"n",
	-- 	"<space>js",
	-- 	"<cmd>JupyniumStartSync nvim_jupynotebook<CR>",
	-- 	{ silent = true, desc = "Jupynium: Start Sync" }
	-- )

	-- Start server, attach, and start sync all in one go
	kb.map("n", "<space>ja", function()
		-- 1. Run the Start and Attach command
		vim.cmd("JupyniumStartAndAttachToServer")

		-- 2. Run the cleanup and sync logic from <space>js with delay
		local launch_delay = 500
		vim.defer_fn(function()
			local file = vim.fn.expand("nvim_jupynotebook.ipynb")
			if vim.fn.filereadable(file) == 1 then
				vim.fn.delete(file)
			end
			vim.cmd("JupyniumStartSync nvim_jupynotebook")
			print("Jupynium: Sync started after delay!")
		end, launch_delay)
	end, { silent = true, desc = "Jupynium: Start, Attach & Sync" })

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
