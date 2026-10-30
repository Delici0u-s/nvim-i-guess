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
--
-- Also per Claude terminal:
-- - <A-e> (utils/jump.lua) re-shows it the plugin's way when it's hidden.
-- - Once Claude connects, it's told which file (and selection) you're in.
--   The plugin only reports that when the cursor moves in a file, and you're
--   in Claude's terminal by the time it connects, so without this Claude
--   doesn't know what "this file" is until you move around a file again.
local M = {}

local maps = {
	{ "<C-x>", "<C-x>", "Claude: pass <C-x> chords to Claude" },
	{ "<C-x><C-x>", "<C-\\><C-n>", "Claude: terminal to normal mode" },
}

--- Send the file/selection of the editor window you were in last. Uses
--- claudecode.selection, which isn't documented API: if an update changes
--- it, warn once and carry on (Claude then learns the file on the next cursor
--- move, as without this).
local warned = false
local function send_editor_context()
	local ok, err = pcall(function()
		local selection = require("claudecode.selection")
		local win = require("utils.jump").last_editor()
		if win then
			vim.api.nvim_win_call(win, selection.update_selection)
		end
		local latest = selection.get_latest_selection()
		if latest then
			selection.send_selection_update(latest)
		end
	end)
	if not ok and not warned then
		warned = true
		vim.notify(
			"Claude: couldn't tell Claude your file on connect (claudecode.nvim changed?"
				.. " see tools/claudecode/terminal.lua): "
				.. tostring(err),
			vim.log.levels.WARN
		)
	end
end

--- Run `fn` once Claude connects, checking every connection_wait_delay ms
--- until connection_timeout (both claudecode.nvim settings).
local function on_connect(fn)
	local claudecode = require("claudecode")
	local config = claudecode.state.config
	local waited = 0
	local function poll()
		if claudecode.is_claude_connected() then
			return fn()
		end
		waited = waited + config.connection_wait_delay
		if waited <= config.connection_timeout then
			vim.defer_fn(poll, config.connection_wait_delay)
		end
	end
	poll()
end

--- Set things up on Claude terminals as they open. The plugin only knows the
--- buffer once it has started the job, hence the schedule.
function M.setup()
	vim.api.nvim_create_autocmd("TermOpen", {
		group = vim.api.nvim_create_augroup("claudecode_terminal_keys", { clear = true }),
		desc = "Claude: terminal keys, <A-e>, editor context on connect",
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
			require("utils.jump").register(ev.buf, function()
				require("claudecode.terminal").open()
			end)
			on_connect(send_editor_context)
		end),
	})
end

return M
