import shutil
import subprocess
import sys

# ── System prerequisites ───────────────────────────────────────────────────────
# Mason (mason-lspconfig + mason-tool-installer) handles LSP servers and
# formatters automatically on first launch. This script only checks the
# external system dependencies that Mason cannot install.

REQUIRED = [
    ("nvim", "Neovim ≥ 0.9"),
    ("git", "git"),
    ("node", "Node.js (npm) — needed for ts_ls, eslint, html, cssls"),
    ("npm", "npm"),
]

RECOMMENDED = [
    ("gcc", "gcc — C compiler (treesitter parsers, cppdbg)"),
    ("python3", "Python ≥ 3.8 (pyright, debugpy)"),
    ("java", "Java JDK 17+ (jdtls)"),
    ("go", "Go (goimports, gofmt)"),
]

OPTIONAL = [
    ("rustc", "Rust toolchain (rust-analyzer, rustfmt)"),
    ("zig", "Zig"),
    ("docker", "Docker (dockerls)"),
    ("terraform", "Terraform (terraformls)"),
    ("alacritty", "Alacritty — configured DAP external terminal"),
]


def check_group(label: str, tools: list[tuple[str, str]]) -> int:
    print(f"\n{label}")
    print("─" * 40)
    missing = 0
    for cmd, description in tools:
        found = shutil.which(cmd) is not None
        status = "✔" if found else "✘ MISSING"
        print(f"  {status:<12} {description}")
        if not found:
            missing += 1
    return missing


def nvim_version_ok() -> bool:
    try:
        out = subprocess.check_output(["nvim", "--version"], text=True)
        first = out.splitlines()[0]  # e.g. "NVIM v0.10.1"
        parts = first.strip().split("v")
        if len(parts) < 2:
            return False
        major, minor, *_ = parts[1].split(".")
        return (int(major), int(minor)) >= (0, 9)
    except Exception:
        return False


def main() -> int:
    print("Neovim config dependency checker")
    print("=" * 40)
    print("NOTE: LSP servers and formatters are managed by Mason.")
    print("      This script only checks system-level prerequisites.")

    total_missing = 0
    total_missing += check_group("Required", REQUIRED)
    total_missing += check_group("Recommended", RECOMMENDED)
    check_group("Optional", OPTIONAL)  # not counted as failures

    print("Jupiter notebook support: https://github.com/kiyoon/jupynium.nvim")
    print()
    if shutil.which("nvim") and not nvim_version_ok():
        print("  ⚠  Neovim found but version is < 0.9 — upgrade recommended.")
        total_missing += 1

    if total_missing == 0:
        print("All required and recommended dependencies are satisfied.")
        return 0
    else:
        print(
            f"{total_missing} required/recommended dependency(s) missing — see above."
        )
        return 1


if __name__ == "__main__":
    sys.exit(main())
