return function()
	require("image").setup({
		backend = "kitty", -- Ghostty and kitty both implement the Kitty Graphics Protocol;
		-- this is the backend name image.nvim expects either way, not literally "must be kitty terminal"
		processor = "magick_cli", -- requires ImageMagick (`magick` or `convert` on PATH)

		integrations = {
			-- Disable markdown/neorg auto-image-preview integrations if you don't
			-- want every markdown image rendered inline globally -- Molten's own
			-- output rendering doesn't go through these integrations, so this is
			-- purely about whether plain markdown image links also preview inline.
			markdown = {
				enabled = false,
				clear_in_insert_mode = false,
				download_remote_images = true,
				only_render_image_at_cursor = false,
				filetypes = { "markdown", "vimwiki" },
			},
			neorg = { enabled = false },
		},

		max_width = 100,
		max_height = 12,
		max_height_window_percentage = math.huge,
		max_width_window_percentage = math.huge,
		window_overlap_clear_enabled = true,
		window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },

		editor_only_render_when_focused = false, -- avoid leftover images when nvim loses focus
		tmux_show_only_in_active_window = true,
	})
end
