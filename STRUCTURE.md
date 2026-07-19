# Config structure

**All keymaps are unchanged from the original config.**

```
init.lua                      leader, shell, then require("configs")
lua/
├── configs/
│   ├── init.lua              load order (see below)
│   ├── core/                 editor options -- no plugin requires
│   │   ├── options.lua       search, responsiveness, completeopt
│   │   ├── visual.lua        numbers, tabstop, netrw, splits
│   │   ├── behaviour.lua     undofile, ShaDa cleanup
│   │   └── commands.lua      :ThemeSwitch, :ThemeSwitchPermanent
│   ├── theme/init.lua        colourscheme
│   ├── lsp/                  everything LSP, in dependency order
│   │   ├── capabilities.lua  global caps -- MUST precede mason
│   │   ├── diagnostics.lua   vim.diagnostic.config
│   │   ├── servers.lua       vim.lsp.config/enable (angel_lsp)
│   │   └── keymaps.lua       buffer-local, on LspAttach
│   ├── keymaps/              non-plugin keymaps, by topic
│   │   ├── editor.lua        <C-l> <C-S> <C-a>
│   │   ├── terminal.lua      <C-X> <C-n> <C-h>n
│   │   └── windows.lua       <C-e>x <C-h>x <C-v>x, <space>t*
│   └── plugins/
│       ├── init.lua          requires lazy.lua
│       ├── lazy.lua          lazy.nvim bootstrap
│       ├── ui/               lualine statuscol indent_blankline
│       │                     snacks ufo render_markdown
│       ├── editor/           cmp luasnip conform lsp_signature
│       │   └── snippets/     LuaSnip definitions
│       ├── lang/             mason mason_tools treesitter lazydev
│       └── tools/            image jupynium dap/
├── plugins/                  lazy.nvim SPECS (not configs)
│   ├── general.lua
│   └── trouble.lua
└── utils/
    ├── keybinds.lua          map() wrapper
    ├── terminal.lua          terminal toggle state machine
    └── log.lua               debug logger
```

## Load order

`init.lua` → `configs/init.lua`, which requires in this order:

1. `core` — options only, no plugins touched
2. `theme` — colours before anything defines highlights
3. `lsp` — **capabilities must be set before mason enables servers**
4. `keymaps`
5. `plugins` — lazy bootstrap; owns every plugin config from here

## Two rules

**Specs and configs are separate.** `lua/plugins/*.lua` declares *when* a plugin
loads. `lua/configs/plugins/**` declares *how* it is configured, and each file
returns a function called by its spec.

**Nothing is auto-discovered.** Every module is explicitly required. Dropping a
file into a directory does nothing until you add a `require` for it. The old
autoloader (`utils/auto_load.lua`) was removed: it globbed directories and ran
plugin configs at startup before their plugins existed on the runtimepath.

Adding a plugin:

```lua
-- lua/plugins/general.lua
{
  "author/foo.nvim",
  event = "VeryLazy",
  config = function()
    require("configs.plugins.ui.foo")()
  end,
},
```

```lua
-- lua/configs/plugins/ui/foo.lua
return function()
  require("foo").setup({})
end
```

## On input latency

This config uses control keys as mapping prefixes (`<C-t>`, `<C-h>`, `<C-v>`,
`<C-e>`, `<C-R>`). Neovim must wait `'timeoutlen'` before deciding you meant the
bare builtin (tag-pop, window-left, visual-block, scroll, redo). That is set to
250ms in `core/options.lua` — lower it further if those still feel sluggish.

which-key's popup `delay` (500ms, in the spec) is separate from `timeoutlen` and
only controls when the hint window appears. It does not delay key execution.
