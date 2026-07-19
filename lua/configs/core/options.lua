-- Core options that were previously unset and left at Vim defaults.
-- Split out from visual.lua/behaviour.lua because these are about editor
-- responsiveness and search/UI behaviour rather than appearance or persistence.

-- Responsiveness -------------------------------------------------------------
vim.opt.updatetime = 250 -- CursorHold delay: drives LSP highlight, snacks.words
-- This config uses control keys as mapping prefixes (<C-t>, <C-h>, <C-v>,
-- <C-e>, <C-R>). Neovim must wait 'timeoutlen' before deciding you meant the
-- bare builtin (tag-pop, window-left, visual-block, scroll, redo), so this is
-- kept low -- it is the single knob that controls how sluggish those feel.
vim.opt.timeoutlen = 250
vim.opt.ttimeoutlen = 10 -- terminal keycode timeout; low avoids <Esc> lag
vim.opt.lazyredraw = false -- must stay off: breaks noice/snacks-style redraws

-- Search ---------------------------------------------------------------------
vim.opt.ignorecase = true
vim.opt.smartcase = true -- case-sensitive only when the pattern has capitals
vim.opt.incsearch = true
vim.opt.hlsearch = true -- <C-l> in keybinds.lua toggles this

-- Editing --------------------------------------------------------------------
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.scrolloff = 8 -- keep context around the cursor
vim.opt.sidescrolloff = 8
vim.opt.virtualedit = "block" -- let visual-block select past EOL
vim.opt.confirm = true -- prompt instead of failing on :q with changes

-- UI -------------------------------------------------------------------------
vim.opt.signcolumn = "yes" -- always reserve it; avoids text jitter on diagnostics
vim.opt.termguicolors = true -- required by the rainglow themes and ibl highlights
vim.opt.mouse = "a"
vim.opt.splitkeep = "screen" -- don't scroll existing windows when splitting
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.shortmess:append("cI") -- drop completion chatter and the intro screen
