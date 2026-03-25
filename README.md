# Requirements

## Core
- Neovim ≥ 0.9 (0.10+ recommended)
- git
- Node.js (npm) — required for `ts_ls`, `eslint`, `html`, `cssls`
- tree-sitter-cli

## Debuggers
- gdb — native C/C++ debugging
- `cppdbg` — installed automatically via mason-nvim-dap
- `debugpy` — installed automatically via mason-nvim-dap

## Language Servers (auto-installed via mason-lspconfig)
| Server | Language |
|---|---|
| `pyright` | Python |
| `clangd` | C / C++ |
| `jdtls` | Java |
| `lua_ls` | Lua |
| `bashls` | Bash |
| `ts_ls` | TypeScript / JavaScript |
| `html`, `cssls`, `eslint` | Web |
| `jsonls`, `yamlls` | JSON / YAML |
| `marksman` | Markdown |
| `cmake`, `mesonlsp` | Build systems |
| `dockerls` | Docker |
| `terraformls` | Terraform |

## Formatters (auto-installed via mason-tool-installer)
| Tool | Language |
|---|---|
| `ruff` | Python (format + lint) |
| `black` | Python (fallback formatter) |
| `isort` | Python (import sorting) |
| `stylua` | Lua |
| `clang-format` | C / C++ |
| `goimports`, `gofmt` | Go |
| `rustfmt` | Rust |
| `codespell` | All files (spellcheck) |

# Recommended

- C compiler (`gcc` or `clang`) — required for `clangd`, `cppdbg`, treesitter parsers
- Python ≥ 3.8 — required for `pyright`, `debugpy`
- Java JDK 17+ — required for `jdtls`
- Go — required for `goimports` / `gofmt`

## Optional (Language Support)
- Rust toolchain (`rust-analyzer`) — for Rust LSP and `rustfmt`
- Zig
- Docker — for `dockerls`
- Terraform — for `terraformls`
