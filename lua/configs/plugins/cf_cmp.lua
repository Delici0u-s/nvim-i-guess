-- configs/plugins/cf_cmp.lua
local M = {}

function M.setup()
  vim.notify("cf_cmp.setup() running", vim.log.levels.INFO)

  local ok, cmp = pcall(require, "cmp")
  if not ok or not cmp then
    vim.notify("nvim-cmp not available: " .. tostring(cmp), vim.log.levels.ERROR)
    return
  end

  local luasnip_ok, luasnip = pcall(require, "luasnip")
  if not luasnip_ok then
    luasnip = nil
    vim.notify("luasnip not available (continuing without snippet support)", vim.log.levels.WARN)
  end

  cmp.setup({
    snippet = {
      expand = function(args)
        if luasnip then
          luasnip.lsp_expand(args.body)
        end
      end,
    },

    mapping = {
      ["<C-Space>"] = cmp.mapping.complete(),
      ["<CR>"] = cmp.mapping.confirm({ select = true }),

      ["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip and luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        else
          fallback()
        end
      end, { "i", "s" }),

      ["<S-Tab>"] = cmp.mapping(function(fallback)
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
      { name = "nvim_lsp" },
      { name = "luasnip" },
      { name = "buffer" },
      { name = "path" },
    }),
  })

  vim.notify("cf_cmp.setup() finished", vim.log.levels.INFO)
end

-- keep same shape as your plugin config expects: require("configs.plugins.cf_cmp")()
return function() M.setup() end

