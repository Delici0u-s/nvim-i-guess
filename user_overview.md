# What's in this config

A reminder list of everything you can *use*: features, keys and commands, one line each.
Leader is **Space**. How things are built: `impl_overview.md`. Requirements: `README.md`.

> [!TIP]
> Forgot a key? `<C-t>k` searches every mapping (and Vim's built-ins) by key or description,
> `<C-t>c` does the same for commands, `<leader>?` shows this buffer's own maps, and pausing on
> any prefix pops up which-key.

## Contents

[Finding things](#finding-things) ·
[Files and windows](#files-and-windows) ·
[Editing](#editing) ·
[Code and LSP](#code-and-lsp) ·
[Terminal and running](#terminal-and-running) ·
[Debugging](#debugging) ·
[Claude Code](#claude-code) ·
[Markdown](#markdown) ·
[Jupyter](#jupyter) ·
[Git](#git) ·
[Look](#look) ·
[Checks](#checks)

## Finding things

| Key | What |
|---|---|
| `<C-t>f` / `<C-t>b` | find files / buffers |
| `<C-t>G` / `<C-t>g` | live grep project / grep open buffers |
| `<C-t>h` / `<C-t>m` | help tags / man pages |
| `<C-t>k` | every mapping + built-in key. `<CR>` runs it, `<A-g>` jumps to its definition, `<A-b>` hides built-ins |
| `<C-t>c` | every command, with descriptions |
| `<leader>?` | which-key: this buffer's maps |
| `]]` / `[[` | next / previous reference of the word under the cursor |

## Files and windows

| Key | What |
|---|---|
| `<C-e>e` / `<C-e>E` | snacks explorer at current file / at cwd (inside: `<C-h>` hidden, `<C-i>` ignored files; deletes go to trash) |
| `<C-e>x` / `<C-h>x` / `<C-v>x` | netrw here / hsplit / vsplit |
| netrw: `D` `d` `%` `R` `<C-l>` | delete / new folder / new file / rename / refresh, on the line under the cursor, also in tree view |
| netrw: `gh` `gl` `gb` `q` | hidden files / list style / banner / close |
| `<A-w>` / `<A-q>` | next / previous window (also from a terminal; count = window N) |
| `<C-q>` | close window; asks if unsaved (`<C-q>` again = discard, `y` = save) |
| `<C-X>` | write and close |
| `<leader>tn` `tc` `to` `tm` `tl` | tab new / close / only / move / list |
| `<leader>.` / `<leader>S` | scratch buffer / pick a scratch buffer |

## Editing

| Key / feature | What |
|---|---|
| `<C-S>` | save (normal + insert); then the run command if run-on-save is on; then macro `@s` |
| `<C-a>{reg}` | run macro from register |
| `<A-v>` | Visual block immediately (bare `<C-v>` waits, it's a prefix) |
| `<C-l>` | toggle search highlight |
| completion | `<C-J>`/`<C-K>` move, `<CR>` confirm; LSP, snippets, buffer, path |
| snippets | `<Tab>`/`<S-Tab>` jump while a snippet is active (`headerguard` in C/C++) |
| autopairs | brackets and quotes close themselves |
| typing-transformer | fixes typos as you type (`cosnt ` → `const `); rules in `plugins/lazy/general.lua` |
| format on save | conform: stylua, ruff/black/isort, clang-format, gofmt, rustfmt, `zig fmt` |
| folds | open by default; `zk` peek fold (else hover), `zR`/`zM` open/close all, `zr`/`zm` by level |
| persistent undo | survives restarts |
| `<C-f>` | search & replace in this file (grug-far, word under cursor prefilled); in Visual mode: within the selection |
| `<C-g>` | search & replace in the whole project; in Visual mode: the selected text prefilled |
| in grug-far | type Search / Replace, results preview live; `\r` replace all, `\s` apply edits made to result lines, `\q` to quickfix, `\c` close, `g?` all keys |
| grug-far: move through matches | `<Down>`/`<Up>` show next / previous match in the code (you stay in grug-far), `<Enter>` jump there, `\o` open without leaving, `\i` preview float, `\j`/`\k` replace this one and go to next / previous |
| `]q` / `[q` | next / previous quickfix entry from any buffer (after `\q` in grug-far or `<C-q>` in a picker); grug-far doesn't set `/`, so `n`/`N` don't follow it |
| `:cdo s/a/b/gc \| update` | builtin alternative: replace in every quickfix match (fill it with `<C-q>` in a grep picker) |
| `*` then `cgn`, `.` | change the next match, repeat on the following ones (`n` skips) |

## Code and LSP

| Key / feature | What |
|---|---|
| `gd` / `gD` | definition / declaration |
| `tgd` `tgD` `tgi` `tgr` | definition / declaration / implementation / references in a new tab |
| `grn` `gra` `grr` `gri` `K` | Neovim built-ins: rename, code action, references, implementation, hover |
| `<leader>f` | format |
| `<leader>th` | toggle inlay hints |
| `<leader>tt…` | Trouble: `x` diagnostics, `X` buffer diagnostics, `s` symbols, `l` LSP lists, `L` loclist, `Q` quickfix |
| diagnostics | shown as lines under the code |
| servers | auto-installed by mason: Lua, Python, C/C++, Java, Bash, JSON, YAML, Markdown, CMake, Meson, TS/JS, HTML, CSS, ESLint, Docker, Terraform, asm, Zig; AngelScript from source |
| Zig | a zls matching your `zig version` is fetched automatically; single `.zig` files (no `build.zig`) get compiler errors on save |
| `:Mason` `:LspInfo` `:ConformInfo` `:checkhealth` | status pages |

## Terminal and running

| Key | What |
|---|---|
| `<C-n>` / `<C-h>n` | toggle vertical / horizontal terminal (hiding keeps the shell) |
| `<C-X>` (terminal) | leave terminal mode |
| `<A-e>` | jump between the editor and the last-used terminal (shell or Claude), keeping modes |
| `<leader>rr` / `:Run [cmd]` | run the project's command (remembered per project) |
| `<leader>rS` | runner menu: run, stop, output, every setting |
| `<leader>ro` / `<leader>rk` | show/hide output / stop |
| `<leader>rs…` | settings: `c` command, `t` where (terminal, split, external window), `d` folder, `s` run on `<C-S>`, `f` focus output while running |

The runner uses your shell's own completion (zsh/fish) in its prompt.

## Debugging

C, C++, Rust, Zig (codelldb) and Python (debugpy, uses the project venv). `F5` asks for a launch
config, then picks a program (newest builds first, **Browse…**, **Type a path…**) and optionally
args. `.vscode/launch.json` is read too. UI choice (`dap-ui`, `dap-view`, `widgets`) is in
`tools/dap/settings.lua`.

| Key | What |
|---|---|
| `F5` / `<leader>dc` | start / continue |
| `F10` `F11` `S-F11` (`<leader>do` `di` `du`) | step over / into / out |
| `F9` / `<leader>dt` | toggle breakpoint |
| `<leader>dB` / `dL` / `dE` | conditional breakpoint / logpoint / exception breakpoints |
| `<leader>db` / `dx` | list / clear breakpoints |
| `<leader>dC` | run to cursor |
| `<leader>dp` / `dR` / `dq` / `dl` | pause / restart / terminate / rerun last |
| `<leader>de` / `dw` | evaluate / watch word or selection |
| `<leader>ds` / `df` | scopes / call stack |
| `<leader>dU` / `dr` | toggle UI / REPL |

## Claude Code

Claude runs in a split and sees your file and selection; its edits show up as diffs here.

| Key | What |
|---|---|
| `<leader>ac` / `af` | toggle / focus Claude |
| `<leader>ar` / `aC` / `am` | resume a conversation / continue the last / pick a model |
| `<leader>ab` | type `@this-file` into Claude's prompt |
| `<leader>as` | selected lines as `@file#Lx-y`; in netrw/explorer: the file(s) under the cursor |
| `<A-c>` (in a picker) | reference the picked files or grep lines |
| `<leader>aa` / `ad` | accept / reject diff (also `<C-s>`/`:w` and `<C-q>` in the proposed window, after editing it if you like) |
| `<leader>aj` / `ax` | jump to a waiting diff / reject all |
| `<leader>aS` / `ao` | status / options (window side, width, diff layout, focus…; saved) |
| `<C-x><C-x>` (Claude terminal) | leave terminal mode (`<C-x>` alone goes to Claude) |

## Markdown

Rendered headings, tables, callouts, plus inline images, `$LaTeX$` and Mermaid (Ghostty/kitty).
Soft wrap on.

| Key | What |
|---|---|
| `<C-R>m` | toggle rendering |
| `<C-R>l` | toggle live image preview while editing |
| `<C-R>w` | toggle wrap (for wide tables) |

Test page: `test/markdown/markdown_view_test.md`.

## Jupyter

Jupynium drives a notebook in Firefox from a `.ju.py` file; `# %%` separates cells.

| Key / command | What |
|---|---|
| `<leader>ja` | start, attach and sync in one go (`jn` start & attach, `js` start sync) |
| `<leader>x` / `<leader>k` | execute cell / kernel hover |
| `<leader>jj` / `jk` | scroll the notebook |
| `<leader>jl1`…`9` | load from browser tab N |

Converting `.ipynb` → `.ju.py`: attach, open the `.ipynb` in the browser, `:JupyniumLoadFromIpynbTab`
(or `<leader>jl<N>`) in a new buffer, save.

## Git

| Key | What |
|---|---|
| `<leader>lg` | lazygit |
| `<leader>gb` | blame current line |

## Look

| Command | What |
|---|---|
| `:ThemeSwitch` | dark/light for this session |
| `:ThemeSwitchPermanent` | same, saved (rainglow themes; names in `configs/theme/init.lua`) |

Statusline shows the debug session; indent guides shade grey → red with depth (dark mode).

## Checks

`python3 SETUP.py` lists missing system tools. Headless tests (`test/*/run.lua`) are listed in
`impl_overview.md` under *Tests and verification*.
