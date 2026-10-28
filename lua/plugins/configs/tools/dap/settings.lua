-- Debugger settings. Plain table, no plugin requires: the lazy spec reads it
-- at startup to decide which UI plugin may load.
return {
	-- Which debugger UI to use. Each lives in tools/dap/ui/<name>.lua; actions
	-- a UI doesn't implement fall back to "widgets".
	--   "dap-ui"   -- rcarriga/nvim-dap-ui: IDE-style panes around the code
	--   "dap-view" -- igorlfs/nvim-dap-view: one tabbed panel + console
	--   "widgets"  -- nvim-dap's built-in floats/sidebars, no extra plugin
	ui = "dap-ui",

	-- mason-nvim-dap adapter names (`:h mason-nvim-dap`), installed on first
	-- use. Each brings default launch configurations for its filetypes, so a
	-- new language usually needs only an entry here.
	--   codelldb -- C, C++, Rust, Zig, Swift
	--   python   -- debugpy
	adapters = { "codelldb", "python" },

	-- Terminal for configurations that ask for an external console
	-- (e.g. a launch.json with "console": "externalTerminal").
	external_terminal = {
		command = os.getenv("TERMINAL") or "ghostty",
		args = { "-e" },
	},

	-- Program picker: directories not descended into when listing executables.
	-- Hidden directories (.git, .venv, .zig-cache, ...) are always skipped.
	picker_skip_dirs = { "node_modules" },

	-- Python: virtualenv directory names looked for upwards from the file
	-- when $VIRTUAL_ENV / $CONDA_PREFIX aren't set.
	venv_dirs = { ".venv", "venv" },
}
