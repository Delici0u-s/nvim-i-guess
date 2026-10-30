-- Keys inside the Claude terminal, where the global terminal-mode maps
-- (configs/keymaps/terminal.lua, windows.lua) would hide Claude Code's own.
--
-- <C-x> is Claude's chord prefix (<C-x><C-k> stop agents, <C-x><C-e> editor,
-- <C-x><C-b> background, <C-x>Enter queue). Globally it leaves terminal mode,
-- which would eat every chord, so here it goes to Claude and <C-x><C-x>
-- leaves terminal mode instead (<C-\><C-n> works everywhere too).
--
-- Kept on purpose: <A-w>/<A-q> window cycling (Claude's <A-w> toggles workflow
-- keywords) and <C-n> (Claude also lists with Down / j).
local M = {}

local maps = {
	{ "<C-x>", "<C-x>", "Claude: pass <C-x> chords to Claude" },
	{ "<C-x><C-x>", "<C-\\><C-n>", "Claude: terminal to normal mode" },
}

--- Set the maps on Claude terminals as they open. The plugin only knows the
--- buffer once it has started the job, hence the schedule.
function M.setup()
	vim.api.nvim_create_autocmd("TermOpen", {
		group = vim.api.nvim_create_augroup("claudecode_terminal_keys", { clear = true }),
		desc = "Claude: terminal keys",
		callback = vim.schedule_wrap(function(ev)
			if
				not vim.api.nvim_buf_is_valid(ev.buf)
				or ev.buf ~= require("claudecode.terminal").get_active_terminal_bufnr()
			then
				return
			end
			for _, map in ipairs(maps) do
				vim.keymap.set("t", map[1], map[2], { buffer = ev.buf, desc = map[3] })
			end
		end),
	})
end

return M
