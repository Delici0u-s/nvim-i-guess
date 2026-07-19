return function()
	local snacks = require("snacks")
	snacks.setup({
		bigfile = { enabled = true },
		dashboard = { enabled = false },
		image = { enabled = false }, -- explicitly off: image.nvim owns the
		-- Kitty graphics protocol session for
		-- Molten; two plugins fighting over the
		-- same terminal escape sequences causes
		-- garbled/duplicate image output
		indent = { enabled = false },
		input = { enabled = true },
		notifier = { enabled = true },
		picker = { enabled = true },
		quickfile = { enabled = true },
		scroll = { enabled = false },
		statuscolumn = { enabled = false },
		words = { enabled = true },
	})
	local kb = require("utils.keybinds")
	-- Picker (replaces your Telescope binds, or coexist)
	kb.map("n", "<C-t>f", function()
		snacks.picker.files()
	end, { desc = "Snacks: find files" })
	kb.map("n", "<C-t>g", function()
		snacks.picker.grep_buffers()
	end, { desc = "Snacks: grep buffer" })
	kb.map("n", "<C-t>G", function()
		snacks.picker.grep()
	end, { desc = "Snacks: live grep" })
	kb.map("n", "<C-t>b", function()
		snacks.picker.buffers()
	end, { desc = "Snacks: buffers" })
	kb.map("n", "<C-t>h", function()
		snacks.picker.help()
	end, { desc = "Snacks: help tags" })
	kb.map("n", "<C-t>m", function()
		snacks.picker.man()
	end, { desc = "Snacks: man pages" })
	-- Notifier (drop-in for nvim-notify)
	vim.notify = snacks.notifier.notify
	-- Words (highlight word under cursor)
	kb.map("n", "]]", function()
		snacks.words.jump(1)
	end, { desc = "Snacks: next word ref" })
	kb.map("n", "[[", function()
		snacks.words.jump(-1)
	end, { desc = "Snacks: prev word ref" })
	-- Scratch buffer
	kb.map("n", "<leader>.", function()
		snacks.scratch()
	end, { desc = "Snacks: scratch" })
	kb.map("n", "<leader>S", function()
		snacks.scratch.select()
	end, { desc = "Snacks: select scratch" })
	-- Git blame / lazygit (if you have it installed)
	kb.map("n", "<leader>gb", function()
		snacks.git.blame_line()
	end, { desc = "Snacks: git blame line" })
	kb.map("n", "<leader>lg", function()
		snacks.lazygit()
	end, { desc = "Snacks: lazygit" })
end
