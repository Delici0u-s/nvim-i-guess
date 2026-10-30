-- Accept/reject/jump to Claude's proposed edits from anywhere, not only from
-- inside the proposed buffer (where :w / <C-s> / <C-x> accept on their own,
-- and <C-q> rejects: mapped here on each proposed buffer).
--
-- Open diffs are tracked through claudecode.nvim's public User events
-- (ClaudeCodeDiffOpened / ClaudeCodeDiffClosed). A diff closes right after it
-- is accepted or rejected (Claude answers with close_tab), so "open" here
-- means "waiting for you".
local M = {}

---@type table<string, {file_path: string, diff_window: integer}> tab_name -> event data
local open = {}

function M.setup()
	local group = vim.api.nvim_create_augroup("claudecode_diffs", { clear = true })
	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = "ClaudeCodeDiffOpened",
		desc = "Claude: track open diffs",
		callback = function(ev)
			open[ev.data.tab_name] = ev.data
			-- <C-q> rejects in every layout. The unified view's buffer is
			-- read-only and counts as modified, so the global <C-q> (and :q)
			-- would ask about unsaved changes first.
			if vim.api.nvim_win_is_valid(ev.data.diff_window) then
				vim.keymap.set("n", "<C-q>", "<cmd>ClaudeCodeDiffDeny<CR>", {
					buffer = vim.api.nvim_win_get_buf(ev.data.diff_window),
					desc = "Claude: reject the diff",
				})
			end
		end,
	})
	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = "ClaudeCodeDiffClosed",
		desc = "Claude: track open diffs",
		callback = function(ev)
			open[ev.data.tab_name] = nil
		end,
	})
end

--- Sort key: tab number, then window number.
local function position(win)
	local tab = vim.api.nvim_tabpage_get_number(vim.api.nvim_win_get_tabpage(win))
	return { tab, vim.api.nvim_win_get_number(win) }
end

--- Open diffs whose proposed window still exists, oldest tab first.
local function list()
	local diffs = {}
	for name, data in pairs(open) do
		if vim.api.nvim_win_is_valid(data.diff_window) then
			diffs[#diffs + 1] = { name = name, file = data.file_path, win = data.diff_window }
		end
	end
	table.sort(diffs, function(a, b)
		local pa, pb = position(a.win), position(b.win)
		return pa[1] < pb[1] or (pa[1] == pb[1] and pa[2] < pb[2])
	end)
	return diffs
end

--- The diff meant: the one in the current tab, else the only one, else ask.
---@param prompt string
---@param fn fun(diff: {name: string, file: string, win: integer})
local function with_diff(prompt, fn)
	local diffs = list()
	if #diffs == 0 then
		return vim.notify("Claude: no diff is waiting", vim.log.levels.INFO)
	end
	local here = vim.tbl_filter(function(d)
		return vim.api.nvim_win_get_tabpage(d.win) == vim.api.nvim_get_current_tabpage()
	end, diffs)
	if #here == 1 or #diffs == 1 then
		return fn(here[1] or diffs[1])
	end
	vim.ui.select(#here > 1 and here or diffs, {
		prompt = prompt,
		format_item = function(d)
			return vim.fn.fnamemodify(d.file, ":~:.")
		end,
	}, function(d)
		if d then
			fn(d)
		end
	end)
end

--- Run a claudecode diff command as if from inside the proposed buffer.
local function resolve(command, verb, past)
	return function()
		with_diff(("Claude: %s which diff?"):format(verb), function(d)
			vim.api.nvim_buf_call(vim.api.nvim_win_get_buf(d.win), function()
				vim.cmd(command)
			end)
			vim.notify(("Claude: %s %s"):format(past, vim.fn.fnamemodify(d.file, ":~:.")))
		end)
	end
end

M.accept = resolve("ClaudeCodeDiffAccept", "accept", "accepted")
M.reject = resolve("ClaudeCodeDiffDeny", "reject", "rejected")

function M.jump()
	with_diff("Claude: go to which diff?", function(d)
		vim.api.nvim_set_current_win(d.win)
	end)
end

return M
