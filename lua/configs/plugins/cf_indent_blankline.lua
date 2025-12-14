return function()
	-- local hooks = require("ibl.hooks")

	-- Hex ↔ RGB helpers (same as before)
	local function hex_to_rgb(hex)
		hex = hex:gsub("#", "")
		return { tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16) }
	end

	local function rgb_to_hex(rgb)
		return string.format("#%02X%02X%02X", rgb[1], rgb[2], rgb[3])
	end

	local function blend_colors(c1, c2, t)
		local r1, g1, b1 = unpack(hex_to_rgb(c1))
		local r2, g2, b2 = unpack(hex_to_rgb(c2))
		return rgb_to_hex({
			math.floor(r1 + (r2 - r1) * t + 0.5),
			math.floor(g1 + (g2 - g1) * t + 0.5),
			math.floor(b1 + (b2 - b1) * t + 0.5),
		})
	end

	-- -- Generate highlight groups and a separate list of names
	local function generate_indent_hl(base_name, hex_list, steps)
		local hl_names = {}
		local segments = #hex_list - 1
		for i = 0, steps - 1 do
			local t = i / (steps - 1)
			-- Determine which segment this step belongs to
			local segment_index = math.min(math.floor(t * segments) + 1, segments)
			local segment_start = hex_list[segment_index]
			local segment_end = hex_list[segment_index + 1]

			-- Local t within this segment
			local segment_t = (t - (segment_index - 1) / segments) * segments

			local color = blend_colors(segment_start, segment_end, segment_t)
			local hl_name = base_name .. (i + 1)
			table.insert(hl_names, hl_name)
			vim.api.nvim_set_hl(0, hl_name, { fg = color })
		end
		return hl_names
	end

	-- progressively worse highlight
	-- Usage: generate highlights before calling ibl setup
	-- local highlight = generate_indent_hl("IndentRed", "#1E1E1E", "#E06C75", 8)
	-- local highlight = generate_indent_hl("IndentRed", "#ADADAD", "#E06C75", 3)
	-- local highlight = generate_indent_hl("IndentRed", "#4A4A4A", "#E06C75", 7)
	-- if more than 20 highlights may god help you
	local highlight = generate_indent_hl("IndentRed", { "#4A4A4A", "#FF000C", "#FF000C" }, 20)

	require("ibl").setup({
		indent = {
			highlight = highlight,
			char = "│",
		},
		whitespace = {
			highlight = highlight,
			remove_blankline_trail = true,
		},
		scope = { enabled = false },
	})
end

-- bootleg simple version that has clear background:
-- local hooks = require("ibl.hooks")
--
-- hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
-- 	-- define a clean FG-only group
-- 	vim.api.nvim_set_hl(0, "MyIndentFG", { fg = "#7C7C7C", bg = nil })
-- end)
--
-- require("ibl").setup({
-- 	indent = {
-- 		highlight = { "MyIndentFG" },
-- 		char = "│",
-- 	},
-- 	whitespace = {
-- 		highlight = { "MyIndentFG" },
-- 		remove_blankline_trail = true,
-- 	},
-- 	scope = { enabled = false },
-- })
