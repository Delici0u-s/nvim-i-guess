return function()
	local kb = require("utils.keybinds")
	local rm = require("render-markdown")

	-- ── Highlights ───────────────────────────────────────────────────────────
	-- The plugin's defaults link heading backgrounds to DiffText/DiffAdd/...,
	-- which rainglow themes paint as solid lime/orange/red blocks. Instead,
	-- derive subtle tints by blending each accent into Normal's background.
	-- Recomputed on ColorScheme so it follows :ThemeSwitch (dark <-> light).

	local function hex(name, attr)
		local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
		return hl[attr] and string.format("#%06x", hl[attr]) or nil
	end

	local function blend(fg, bg, alpha)
		local function ch(c, i)
			return tonumber(c:sub(i, i + 1), 16)
		end
		local out = "#"
		for _, i in ipairs({ 2, 4, 6 }) do
			out = out .. string.format("%02x", math.floor(ch(fg, i) * alpha + ch(bg, i) * (1 - alpha) + 0.5))
		end
		return out
	end

	local function set_highlights()
		local bg = hex("Normal", "bg") or (vim.o.background == "dark" and "#1e1e1e" or "#ffffff")
		local fg = hex("Normal", "fg") or (vim.o.background == "dark" and "#d0d0d0" or "#303030")
		local muted = hex("Comment", "fg") or blend(fg, bg, 0.4)

		-- One accent per heading level, pulled from the active theme.
		local accents = {
			hex("Title", "fg") or hex("Function", "fg") or fg,
			hex("String", "fg") or fg,
			hex("Statement", "fg") or fg,
			hex("DiffAdd", "bg") or fg,
			hex("DiffText", "bg") or fg,
			hex("DiffDelete", "bg") or fg,
		}

		local set = function(name, val)
			vim.api.nvim_set_hl(0, "RenderMarkdown" .. name, val)
		end

		for i, accent in ipairs(accents) do
			set("H" .. i, { fg = accent, bold = true })
			set("H" .. i .. "Bg", { fg = accent, bg = blend(accent, bg, 0.16), bold = true })
		end

		local code_bg = blend(fg, bg, 0.06)
		set("Code", { bg = code_bg })
		set("CodeBorder", { bg = blend(fg, bg, 0.10) })
		set("CodeInline", { fg = accents[2], bg = blend(fg, bg, 0.10) })
		set("CodeInfo", { fg = muted, italic = true })

		set("Quote", { fg = accents[1] })
		set("Bullet", { fg = accents[1] })
		set("Dash", { fg = muted })
		set("Link", { fg = accents[1], underline = true })
		set("Checked", { fg = accents[4] })
		set("Unchecked", { fg = muted })
		set("Todo", { fg = accents[2] })
		set("TableHead", { fg = muted })
		set("TableRow", { fg = muted })
	end

	set_highlights()
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("RenderMarkdownTints", { clear = true }),
		callback = set_highlights,
	})

	-- ── Options ──────────────────────────────────────────────────────────────
	-- Pick which option set is active:
	--   "obsidian"        preset only, plugin defaults otherwise
	--   "custom"          the hand-tuned overrides below, no preset
	--   "obsidian_custom" obsidian preset + the overrides on top
	-- With `preset`, the plugin merges the preset under the user options,
	-- so anything not overridden keeps tracking upstream defaults.
	local variant = "obsidian"

	local custom = {
		-- Keep raw markdown visible on the cursor line only.
		anti_conceal = { enabled = true },

		heading = {
			sign = false,
			position = "overlay",
			icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
			-- Block-width "pill" headings instead of full-window bars.
			width = "block",
			left_pad = 1,
			right_pad = 2,
			min_width = 30,
			-- Thin rules above/below each heading, drawn as virtual lines so
			-- they don't need blank lines in the source.
			border = true,
			border_virtual = true,
			above = "▁",
			below = "▔",
		},

		code = {
			sign = false,
			style = "full",
			width = "block",
			min_width = 60,
			left_pad = 2,
			right_pad = 2,
			border = "thin",
			language_pad = 1,
			above = "▁",
			below = "▔",
			inline_pad = 1,
		},

		bullet = {
			icons = { "●", "○", "◆", "◇" },
			right_pad = 1,
		},

		checkbox = {
			right_pad = 1,
			unchecked = { icon = "󰄱 " },
			checked = { icon = "󰄵 ", scope_highlight = "@markup.strikethrough" },
			custom = {
				todo = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" },
				important = { raw = "[!]", rendered = "󰀦 ", highlight = "DiagnosticWarn" },
			},
		},

		quote = { icon = "▎", repeat_linebreak = true },

		pipe_table = {
			preset = "round",
			cell = "padded",
		},
	}

	local variants = {
		obsidian = { preset = "obsidian" },
		custom = custom,
		obsidian_custom = vim.tbl_deep_extend("force", { preset = "obsidian" }, custom),
	}
	-- Integration with snacks.image (applies to every variant):
	-- * latex off: snacks renders math as real images; render-markdown's text
	--   converters (utftex/latex2text) would draw it a second time.
	-- * mermaid/math blocks left raw: render-markdown's default code border
	--   ("hide") conceal_lines the closing fence, and snacks hangs the
	--   rendered diagram off that exact line, so it vanished with it.
	rm.setup(vim.tbl_deep_extend("force", variants[variant], {
		latex = { enabled = false },
		code = { disable = { "mermaid", "math" } },
	}))

	-- ── Toggles ──────────────────────────────────────────────────────────────
	-- Image hooks live in snacks_image.lua (snacks has no public API for them).
	local images = require("plugins.configs.ui.snacks_image")

	kb.map("n", "<C-R>m", function()
		rm.toggle()
		vim.g.markdown_images_off = not vim.g.markdown_images_off
		images.refresh()
	end, { silent = true, desc = "Toggle markdown rendering (render-markdown + images)" })

	-- Live preview: while the cursor is inside an image/math/mermaid source,
	-- show the rendered result below it instead of hiding it. On by default.
	kb.map("n", "<C-R>l", function()
		vim.g.markdown_live_off = not vim.g.markdown_live_off
		images.refresh()
		vim.notify("Markdown live preview " .. (vim.g.markdown_live_off and "off" or "on"))
	end, { silent = true, desc = "Toggle markdown live image preview" })

	-- Wide tables break under soft wrap (known render-markdown/neovim limit:
	-- wrap points are computed before conceal). Flip wrap when reading them.
	kb.map("n", "<C-R>w", function()
		vim.wo.wrap = not vim.wo.wrap
	end, { silent = true, desc = "Toggle line wrap" })
end
