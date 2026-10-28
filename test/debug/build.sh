#!/usr/bin/env sh
# Builds the native test programs with debug info into test/debug/build/.
# Languages whose compiler is missing are skipped, not failed.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
out="$here/build"
mkdir -p "$out"

if command -v cc >/dev/null; then
	cc -g -O0 "$here/c/main.c" -o "$out/c_demo" && echo "built c_demo"
else echo "skip c (no cc)"; fi

if command -v zig >/dev/null; then
	(cd "$out" && zig build-exe -O Debug "$here/zig/main.zig" -femit-bin="$out/zig_demo") && echo "built zig_demo"
else echo "skip zig (no zig)"; fi

if command -v rustc >/dev/null; then
	rustc -g -C opt-level=0 "$here/rust/main.rs" -o "$out/rust_demo" && echo "built rust_demo"
else echo "skip rust (no rustc)"; fi
