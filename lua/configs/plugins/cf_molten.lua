local M = {}

function M.init()
	vim.g.molten_image_provider = "image.nvim"
	-- vim.g.molten_output_win_max_height = 20

	-- TURN THIS OFF to stop the floating window from blocking your hovers
	vim.g.molten_auto_open_output = false

	vim.g.molten_wrap_output = true
	vim.g.molten_virt_text_output = true
	vim.g.molten_virt_lines_off_by_1 = true
	vim.g.molten_use_border_highlights = true
	vim.g.molten_cell_marker = "# %%"

	-- Optional: Limit virtual text lines so massive errors don't clutter your screen
	-- vim.g.molten_virt_text_max_lines = 15
end

function M.config()
	local kb = require("utils.keybinds")

	local function feed(keys)
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
	end

	kb.map("n", "<space>jq", "<cmd>MoltenDeinit<CR>", {
		silent = true,
		desc = "Molten: Deinit kernel",
	})

	kb.map("n", "<space>x", function()
		local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
		local last_line = vim.api.nvim_buf_line_count(0)

		local start_line = 1
		local end_line = last_line

		-- 1. Search upwards for the start of the cell
		for i = cursor_line, 1, -1 do
			local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
			if line and line:match("^# %%") then
				start_line = i + 1 -- Start evaluating right after the comment marker
				break
			end
		end

		-- 2. Search downwards for the end of the cell
		for i = cursor_line + 1, last_line do
			local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
			if line and line:match("^# %%") then
				end_line = i - 1 -- End right before the next cell starts
				break
			end
		end

		-- 3. Prevent running if the cell is completely empty
		if start_line > end_line then
			return
		end

		-- 4. Send the range to Molten (triggers kernel prompt if uninitialized)
		vim.fn.MoltenEvaluateRange(start_line, end_line)
	end, {
		silent = true,
		desc = "Molten: Evaluate current # %% cell",
	})

	-- kb.map("n", "<space>x", function()
	-- 	vim.cmd("MoltenEvaluateOperator")
	-- 	feed("ip")
	-- end, {
	-- 	silent = true,
	-- 	desc = "Molten: Evaluate current paragraph/cell",
	-- })

	kb.map("n", "<space>jx", "<cmd>MoltenEvaluateOperator<CR>", {
		silent = true,
		desc = "Molten: Evaluate (operator, needs motion)",
	})

	kb.map("v", "<space>jv", "<cmd>MoltenEvaluateVisual<CR>", {
		silent = true,
		desc = "Molten: Evaluate visual",
	})

	kb.map("n", "<space>jr", "<cmd>MoltenReevaluateCell<CR>", {
		silent = true,
		desc = "Molten: Re-evaluate cell",
	})

	kb.map("n", "<space>jc", "<cmd>MoltenEvaluateLine<CR>", {
		silent = true,
		desc = "Molten: Evaluate line",
	})

	kb.map("n", "<space>jo", "<cmd>MoltenShowOutput<CR>", {
		silent = true,
		desc = "Molten: Show output",
	})

	kb.map("n", "<space>jh", "<cmd>MoltenHideOutput<CR>", {
		silent = true,
		desc = "Molten: Hide output",
	})

	kb.map("n", "<space>jd", "<cmd>MoltenDelete<CR>", {
		silent = true,
		desc = "Molten: Delete cell output",
	})

	kb.map("n", "<space>jk", "<cmd>MoltenInfo<CR>", {
		silent = true,
		desc = "Molten: Kernel info",
	})

	kb.map("n", "<space>jR", "<cmd>MoltenRestart!<CR>", {
		silent = true,
		desc = "Molten: Restart kernel (hard)",
	})

	kb.map("n", "<space>jS", "<cmd>MoltenSave<CR>", {
		silent = true,
		desc = "Molten: Save outputs",
	})

	kb.map("n", "<space>jL", "<cmd>MoltenLoad<CR>", {
		silent = true,
		desc = "Molten: Load outputs",
	})

	vim.api.nvim_create_autocmd("BufEnter", {
		pattern = { "*.ju.py", "*.sage" },
		callback = function(args)
			local bufname = vim.api.nvim_buf_get_name(args.buf)
			if bufname == "" then
				return
			end

			local molten_file = bufname .. ".molten"
			if vim.fn.filereadable(molten_file) ~= 1 then
				return
			end

			if vim.b[args.buf].molten_autoloaded then
				return
			end
			vim.b[args.buf].molten_autoloaded = true

			vim.schedule(function()
				pcall(vim.cmd, "MoltenLoad")
			end)
		end,
		desc = "Molten: auto-load saved cell outputs",
	})
end

return M
