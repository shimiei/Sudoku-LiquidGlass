#!/usr/bin/env bash
# Compile every Objective-C file of the app without linking (fast syntax/type check).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDKROOT="${SDKROOT:-$HOME/theos/sdks}"
SDK="$(ls -1d "$SDKROOT"/iPhoneOS*.sdk 2>/dev/null | sort -V | tail -1)"
MINIOS="${MINIOS:-15.0}"
OUT="$(mktemp -d)"

fail=0
for f in "$ROOT"/Sudoku/*.m; do
    printf -- '--- %s\n' "$(basename "$f")"
    clang -target "arm64-apple-ios$MINIOS" -isysroot "$SDK" -fobjc-arc -O2 \
          -Wall -Wextra -Wno-unused-parameter -Wno-unused-function \
          -I"$ROOT/Sudoku" -c "$f" -o "$OUT/$(basename "$f" .m).o" || fail=1
done
rm -rf "$OUT"
exit $fail
