local M = {}

function M.init()
	vim.g.molten_image_provider = "image.nvim"

	-- Output behavior
	vim.g.molten_auto_open_output = false
	vim.g.molten_wrap_output = true
	vim.g.molten_output_show_exec_time = false

	-- Text output inline
	vim.g.molten_virt_text_output = false
	vim.g.molten_virt_text_max_lines = 20

	-- Make output appear before next #%%
	vim.g.molten_cover_empty_lines = true
	vim.g.molten_virt_lines_off_by_1 = false

	-- Reserve space for output
	vim.g.molten_output_virt_lines = true

	-- Images only in output window
	vim.g.molten_image_location = "float"

	-- Floating window tweaks
	vim.g.molten_output_win_max_height = 40
	vim.g.molten_output_win_border = { "", "━", "", "" }
	vim.g.molten_output_show_more = true
	-- vim.g.molten_output_crop_border = false

	vim.g.molten_use_border_highlights = true
	vim.g.molten_cell_marker = "# %%"
end

function M.config()
	local kb = require("utils.keybinds")

	---------------------------------------------------------------------------
	-- Helpers
	---------------------------------------------------------------------------

	local function get_current_cell()
		local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
		local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

		local start_line = 1
		local end_line = #lines

		for i = cursor_line, 1, -1 do
			if lines[i] and lines[i]:match("^# %%") then
				start_line = i + 1
				break
			end
		end

		for i = cursor_line + 1, #lines do
			if lines[i] and lines[i]:match("^# %%") then
				end_line = i - 1
				break
			end
		end

		return start_line, end_line
	end

	local function evaluate_current_cell()
		local start_line, end_line = get_current_cell()

		if start_line <= end_line then
			vim.fn.MoltenEvaluateRange(start_line, end_line)
		end
	end

	---------------------------------------------------------------------------
	-- Execution
	---------------------------------------------------------------------------

	kb.map("n", "<space>x", evaluate_current_cell, {
		silent = true,
		desc = "Molten: Evaluate current # %% cell",
	})

	kb.map("n", "<space>X", function()
		evaluate_current_cell()

		local current = vim.api.nvim_win_get_cursor(0)[1]
		local next_cell = vim.fn.search("^# %%", "W")

		if next_cell ~= 0 and next_cell ~= current then
			vim.api.nvim_win_set_cursor(0, { next_cell, 0 })
		end
	end, {
		silent = true,
		desc = "Molten: Evaluate cell and jump to next",
	})

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

	---------------------------------------------------------------------------
	-- Navigation
	---------------------------------------------------------------------------

	kb.map("n", "<space>jc", function()
		vim.fn.search("^# %%", "W")
	end, {
		silent = true,
		desc = "Next cell",
	})

	kb.map("n", "<space>jc", function()
		vim.fn.search("^# %%", "bW")
	end, {
		silent = true,
		desc = "Previous cell",
	})

	---------------------------------------------------------------------------
	-- Output
	---------------------------------------------------------------------------

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

	---------------------------------------------------------------------------
	-- Kernel
	---------------------------------------------------------------------------

	kb.map("n", "<space>jq", "<cmd>MoltenDeinit<CR>", {
		silent = true,
		desc = "Molten: Deinit kernel",
	})

	-- kb.map("n", "<space>jk", "<cmd>MoltenInfo<CR>", {
	-- 	silent = true,
	-- 	desc = "Molten: Kernel info",
	-- })

	kb.map("n", "<space>jR", "<cmd>MoltenRestart!<CR>", {
		silent = true,
		desc = "Molten: Restart kernel (hard)",
	})

	kb.map("n", "<space>ji", function()
		vim.ui.input({
			prompt = "Kernel: ",
			default = "python3",
		}, function(kernel)
			if kernel and kernel ~= "" then
				vim.cmd("MoltenInit " .. kernel)
			end
		end)
	end, {
		silent = true,
		desc = "Molten: Initialize kernel",
	})

	---------------------------------------------------------------------------
	-- Persistence
	---------------------------------------------------------------------------

	kb.map("n", "<space>jS", "<cmd>MoltenSave<CR>", {
		silent = true,
		desc = "Molten: Save outputs",
	})

	kb.map("n", "<space>jL", "<cmd>MoltenLoad<CR>", {
		silent = true,
		desc = "Molten: Load outputs",
	})

	vim.api.nvim_create_autocmd("BufWritePost", {
		pattern = { "*.ju.py", "*.sage" },
		callback = function()
			pcall(vim.cmd, "MoltenSave")
		end,
		desc = "Molten: auto-save outputs",
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
		desc = "Molten: auto-load saved outputs",
	})
end

return M
