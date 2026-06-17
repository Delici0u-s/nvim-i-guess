return function()
	local conform = require("conform")

	---------------------------------------------------------------------------
	-- Utilities
	---------------------------------------------------------------------------

	local function normalize_names(names)
		if type(names) == "string" then
			return { names }
		end
		return names or {}
	end

	local function get_available(names, bufnr)
		local result = {}
		for _, name in ipairs(normalize_names(names)) do
			local info = conform.get_formatter_info(name, bufnr)
			if info and info.available then
				result[#result + 1] = name
			end
		end
		return result
	end

	local function with_opts(formatters, opts)
		if not opts or vim.tbl_isempty(opts) then
			return formatters
		end
		local result = vim.deepcopy(formatters)
		for k, v in pairs(opts) do
			result[k] = v
		end
		return result
	end

	---------------------------------------------------------------------------
	-- Public helpers
	---------------------------------------------------------------------------

	-- Runs *all available* formatters from a list (in order)
	-- Optionally attaches formatter options
	local function safe(names, opts)
		names = normalize_names(names)
		opts = opts or {}

		return function(bufnr)
			local available = get_available(names, bufnr)
			if #available == 0 then
				return {}
			end
			return with_opts(available, opts)
		end
	end

	-- Priority resolution:
	-- groups can be:
	--   "formatter"
	--   { "formatter1", "formatter2" }
	--   { names = {...}, opts = {...} }
	local function safe_priority(groups)
		return function(bufnr)
			for _, group in ipairs(groups) do
				local names, opts

				if type(group) == "string" then
					names = { group }
				elseif group.names then
					names = group.names
					opts = group.opts
				else
					names = group
				end

				local available = get_available(names, bufnr)
				if #available > 0 then
					return with_opts(available, opts)
				end
			end
			return {}
		end
	end

	---------------------------------------------------------------------------
	-- Setup
	---------------------------------------------------------------------------
	conform.formatters.zigfmt = {
		command = "zig",
		args = { "fmt", "--stdin" },
		stdin = true,
	}

	conform.setup({
		formatters_by_ft = {
			lua = safe("stylua"),
			go = safe({ "goimports", "gofmt" }),
			rust = safe("rustfmt", { lsp_format = "fallback" }),
			python = safe_priority({

				"ruff_format",
				{
					names = { "isort", "black" },
					opts = { lsp_format = "fallback" },
				},
			}),
			c = safe("clang-format"),
			cpp = safe("clang-format"),
			zig = safe("zigfmt"), -- <-- this was never added
			["*"] = safe("codespell"),
			["_"] = safe("trim_whitespace"),
		},
		-- formatters_by_ft = {
		-- 	-- Simple
		-- 	lua = safe("stylua"),
		--
		-- 	-- Sequential (run all that are available)
		-- 	go = safe({ "goimports", "gofmt" }),
		--
		-- 	-- Formatter with options
		-- 	rust = safe("rustfmt", { lsp_format = "fallback" }),
		--
		-- 	-- Priority with rich config
		-- 	python = safe_priority({
		-- 	}),
		--
		-- 	-- Run everywhere if available
		-- 	["*"] = safe("codespell"),
		--
		-- 	-- True fallback (only used if nothing else matches)
		-- 	["_"] = safe("trim_whitespace"),
		--
		-- 	c = safe("clang-format"),
		-- 	cpp = safe("clang-format"),
		-- },

		format_on_save = {
			lsp_format = "fallback",
			timeout_ms = 500,
		},

		log_level = vim.log.levels.ERROR,
		notify_on_error = true,
		notify_no_formatters = true,
	})
end
