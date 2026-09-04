local M = {}

local log = require("utils.log")

function M.setup()
	-- local ok, cmp = pcall(require, "cmp")
	-- if not ok or not cmp then
	--     log.write("nvim-cmp not available: " .. tostring(cmp))
	--     return
	-- end
	local ok, cmp = pcall(require, "cmp")
	if not ok then
		return
	end

	-- LSP capabilities are advertised in configs/general/lsp_capabilities.lua,
	-- which runs before any server starts. Setting them here (on InsertEnter)
	-- was too late for servers that had already attached.

	local luasnip_ok, luasnip = pcall(require, "luasnip")
	if not luasnip_ok then
		luasnip = nil
		log.write("luasnip not available (continuing without snippet support)")
	end

	cmp.setup({
		snippet = {
			expand = function(args)
				if luasnip then
					luasnip.lsp_expand(args.body)
				end
			end,
		},

		window = {
			completion = cmp.config.window.bordered(),
			documentation = cmp.config.window.bordered(),
		},

		mapping = {
			-- ["<C-Space>"] = cmp.mapping.complete(),
			["<CR>"] = cmp.mapping.confirm({
				select = true,
			}),

			["<C-J>"] = cmp.mapping(function(fallback)
				if cmp.visible() then
					cmp.select_next_item()
				elseif luasnip and luasnip.expand_or_jumpable() then
					luasnip.expand_or_jump()
				else
					fallback()
				end
			end, { "i", "s" }),

			["<C-K>"] = cmp.mapping(function(fallback)
				if cmp.visible() then
					cmp.select_prev_item()
				elseif luasnip and luasnip.jumpable(-1) then
					luasnip.jump(-1)
				else
					fallback()
				end
			end, { "i", "s" }),
		},

		sources = cmp.config.sources({
			{ name = "nvim_lsp", priority = 100 },
			{ name = "luasnip" },
			{ name = "buffer" },
			{ name = "path" },
		}, {
			{ name = "buffer" },
		}),
		sorting = {
			priority_weight = 1.0,
			comparators = {
				cmp.config.compare.score,
				cmp.config.compare.recently_used,
				cmp.config.compare.locality,
			},
		},
	})
end
-- local function debug_lsp_completion()
-- 	local clients = vim.lsp.get_clients({ bufnr = 0 })
--
-- 	for _, client in ipairs(clients) do
-- 		if client:supports_method("textDocument/completion") then
-- 			local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
--
-- 			vim.lsp.buf_request(0, "textDocument/completion", params, function(err, result)
-- 				vim.notify(
-- 					vim.inspect({
-- 						client = client.name,
-- 						err = err,
-- 						result = result,
-- 					}),
-- 					vim.log.levels.INFO
-- 				)
-- 			end)
-- 		end
-- 	end
-- end
--
-- vim.keymap.set("i", "<C-M>", debug_lsp_completion, { buffer = true })

-- keep same shape as your plugin config expects: require("configs.plugins.editor.cmp")()
return function()
	M.setup()
end
