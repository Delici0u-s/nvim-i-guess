local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

-- Header guard snippet for C/C++ headers (with proper spacing)
ls.add_snippets("cpp", {
	s("headerguard", {
		-- #ifndef and #define
		f(function(_, snip)
			local full_path = vim.fn.expand("%:p")
			local cwd = vim.fn.getcwd()
			local relative_path = full_path:sub(#cwd + 2)

			local parts = {}
			for part in relative_path:gmatch("[^/\\]+") do
				table.insert(parts, part)
			end

			local filename = parts[#parts]:match("(.+)%..+$") or parts[#parts]
			parts[#parts] = filename

			local macro = table.concat(parts, "_"):upper() .. "_H"

			return {
				"#ifndef " .. macro,
				"#define " .. macro,
			}
		end, {}),

		t({ "", "" }), -- empty lines after #define
		t({ "", "" }), -- empty lines after #define
		i(0, "/* your code here */"),
		t({ "", "" }), -- empty line before #endif
		t({ "", "" }), -- empty line before #endif
		t({ "#endif" }),
	}),
})
