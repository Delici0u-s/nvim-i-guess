# Debugger test

Small programs in each debugged language, all doing the same thing: summing the scores of four
players in a loop. The loop body has a `BREAK` comment, which is where breakpoints go.

| Language | Source | Built program |
|---|---|---|
| C | `c/main.c` | `build/c_demo` |
| Zig | `zig/main.zig` | `build/zig_demo` |
| Rust | `rust/main.rs` | `build/rust_demo` |
| Python | `python/main.py` | (runs the source) |

## Build

```sh
test/debug/build.sh
```

This builds with debug info into `test/debug/build/` (gitignored). It skips languages whose
compiler is missing.

## Automatic check

```sh
nvim --headless -c "luafile test/debug/run.lua"
```

The script uses the full config. It checks that:

- the DAP config loads without errors and the adapters from `settings.lua` are registered
- every debugger key is mapped and has a description
- the program picker finds the built programs
- for each language, a real session stops on the `BREAK` line, the UI actions (scopes, frames, eval,
  toggle, watch) don't error, and terminating ends the session

It exits non-zero on failure. Optional environment variables:

- `DAP_TEST_UI=dap-view` tests a different UI than `settings.lua` selects (`dap-ui`, `dap-view`, `widgets`)
- `DAP_TEST_ONLY=python` runs a single language

To test every UI in one go:

```sh
for ui in dap-ui dap-view widgets; do DAP_TEST_UI=$ui nvim --headless -c "luafile test/debug/run.lua"; done
```

## Manual walkthrough (and comparing UIs)

Start Neovim in the config root, so the program picker sees `test/debug/build/`.

- [ ] Open `test/debug/c/main.c` and go to the `BREAK` line. Press `F9`: a red `●` appears.
- [ ] Press `F5` and pick **LLDB: Launch (args)**. Pick `test/debug/build/c_demo` (last pick and
      newest builds come first; at the bottom, **Browse…** walks directories with `../` to go up and
      **Type a path…** takes any path) and enter
      `one "two words"` as arguments. The UI opens, the line is highlighted
      and the statusline shows the session.
- [ ] `F10` / `F11` / `S-F11` step; inline virtual text shows `sum`, `i`.
- [ ] `<leader>dw` on `sum` adds a watch, `<leader>de` evaluates under the cursor (try a visual
      selection of `players[i].score`), `<leader>ds` scopes, `<leader>df` call stack.
- [ ] `<leader>dx`, then `<leader>dB` with `i == 2`: `F5` stops only on the third player.
- [ ] `<leader>dL` with `sum is {sum}`: logs to the console without stopping.
- [ ] `<leader>dq` ends the session and the UI closes.
- [ ] Repeat with `zig/main.zig`, `rust/main.rs` and `python/main.py` (Python picks the program
      from the current file and uses `.venv` if one exists).

To compare UIs, change `ui` in `lua/plugins/configs/tools/dap/settings.lua` to `"dap-ui"`,
`"dap-view"` or `"widgets"`, restart Neovim, and run the walkthrough again.
