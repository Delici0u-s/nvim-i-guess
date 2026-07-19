return function()
	local kb = require("utils.keybinds")

	-- =========================================================================
	-- 1. PLUGIN SETUP
	-- =========================================================================
	require("jupynium").setup({
		use_default_keybindings = false,
		textobjects = {
			use_default_keybindings = false,
		},
		firefox_profiles_ini_path = vim.fn.expand("~/.mozilla/firefox/profiles.ini"),
		firefox_profile_name = "Jupynium",
	})

	-- =========================================================================
	-- 2. CONSTANTS & STATE
	-- =========================================================================
	-- Capture the absolute path immediately. This ensures we always target
	-- the correct file even if the user changes directories (:cd) mid-session.
	local notebook_name = "nvim_jupynotebook"
	local notebook_path = vim.fn.fnamemodify(notebook_name .. ".ipynb", ":p")
	local checkpoints_dir = vim.fn.fnamemodify(notebook_path, ":h") .. "/.ipynb_checkpoints"

	local function clean_notebook_file()
		if vim.fn.filereadable(notebook_path) == 1 then
			vim.fn.delete(notebook_path)
		end
		if vim.fn.isdirectory(checkpoints_dir) == 1 then
			vim.fn.delete(checkpoints_dir, "rf")
		end
	end

	-- Smart Polling: Recursively tries to sync until the server is ready
	local function smart_sync_poll(retries)
		retries = retries or 20 -- Max attempts (10 seconds limit)

		if retries <= 0 then
			vim.notify("Jupynium: Server took too long to attach. Sync aborted.", vim.log.levels.ERROR)
			return
		end

		local success = pcall(function()
			vim.cmd("JupyniumStartSync " .. notebook_name)
		end)

		if success then
			vim.notify("Jupynium: Attached and Sync started!", vim.log.levels.INFO)
		else
			vim.defer_fn(function()
				smart_sync_poll(retries - 1)
			end, 500)
		end
	end

	-- =========================================================================
	-- 4. AUTO-COMMANDS (CLEANUP HOOK)
	-- =========================================================================
	-- Delete the specific absolute path file when Neovim exits
	vim.api.nvim_create_autocmd("VimLeave", {
		pattern = "*",
		callback = clean_notebook_file,
	})

	-- =========================================================================
	-- 5. KEYBINDINGS
	-- =========================================================================

	-- Cell Execution
	kb.map("n", "<space>x", "<cmd>JupyniumExecuteSelectedCells<CR>", { silent = true, desc = "Jupynium: Execute" })

	-- Server Connection
	kb.map(
		"n",
		"<space>jn",
		"<cmd>JupyniumStartAndAttachToServer<CR>",
		{ silent = true, desc = "Jupynium: Start & Attach" }
	)

	-- Buffer Synchronization (Manual)
	kb.map("n", "<space>js", function()
		clean_notebook_file()
		vim.cmd("JupyniumStartSync " .. notebook_name)
	end, { silent = true, desc = "Jupynium: Start Sync" })

	-- All-in-One: Server, Attach & Sync (Smart Wait)
	kb.map("n", "<space>ja", function()
		clean_notebook_file()
		vim.cmd("JupyniumStartAndAttachToServer")
		smart_sync_poll()
	end, { silent = true, desc = "Jupynium: Start, Attach & Sync" })

	kb.map("n", "<space>jj", "<cmd>JupyniumScrollDown<CR>", { silent = true, desc = "Jupynium: scroll down" })
	kb.map("n", "<space>jk", "<cmd>JupyniumScrollUp<CR>", { silent = true, desc = "Jupynium: scroll up" })
	kb.map("n", "<space>k", "<cmd>JupyniumKernelHover<CR>", { silent = true, desc = "Jupynium: scroll down" })

	-- Tab Navigation (<space>jl1 .. <space>jl9)
	for i = 1, 9 do
		kb.map(
			"n",
			"<space>jl" .. i,
			"<cmd>JupyniumLoadFromIpynbTab " .. i .. "<CR>",
			{ silent = true, desc = "Jupynium: Load from tab " .. i }
		)
	end
end
