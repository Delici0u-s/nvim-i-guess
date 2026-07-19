return function()
	local snacks = require("snacks")
	snacks.setup({
		bigfile = { enabled = true },
		dashboard = { enabled = false },
		explorer = {
			enabled = true,
			-- false: netrw still handles :Ex/:Hex/:Vex and scp:// URLs.
			-- Setting true routes `nvim <dir>` and directory buffers to snacks,
			-- but it hooks BufEnter in a way that has historically been fragile.
			replace_netrw = false,
			trash = true, -- delete via system trash, not unlink
		},
		picker = {
			enabled = true,
			sources = {
				explorer = {
					hidden = true, -- show dotfiles by default
					ignored = false, -- but respect .gitignore
					auto_close = false,
			  layout = { preset = "sidebar", preview = false },
			  win = {
				  list = {
					  keys = {
						  ["<C-h>"] = "toggle_hidden",
						  ["<C-i>"] = "toggle_ignored",
					  },
				  },
			  },
				},
			},
		},
		image = { enabled = false }, -- explicitly off: image.nvim owns the
		-- Kitty graphics protocol session for
		-- Molten; two plugins fighting over the
		-- same terminal escape sequences causes
		-- garbled/duplicate image output
		indent = { enabled = false },
		input = { enabled = true },
		notifier = { enabled = true },
		quickfile = { enabled = true },
		scroll = { enabled = false },
		statuscolumn = { enabled = false },
		words = { enabled = true },
	})
	local kb = require("utils.keybinds")
	-- Pickers (<C-t> prefix). Telescope was removed; snacks.picker covers these.
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
	-- Explorer. <C-e> prefix mirrors netrw's <C-e>x.
	kb.map("n", "<C-e>e", function()
	snacks.explorer.reveal()
	end, { desc = "Snacks: explorer (reveal current file)" })

	kb.map("n", "<C-e>E", function()
	snacks.explorer({ cwd = vim.uv.cwd() })
	end, { desc = "Snacks: explorer (cwd)" })
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
