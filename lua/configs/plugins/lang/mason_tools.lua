return function()
	require("mason-tool-installer").setup({
		ensure_installed = {
			-- formatters used by conform (see editor/conform.lua)
			"ruff", -- provides ruff_format
			"black",
			"isort",
			"stylua",
			"clang-format",
		},
		auto_update = false,
		run_on_start = true,
	})
end
