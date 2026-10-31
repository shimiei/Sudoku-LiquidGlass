#!/usr/bin/env bash
# 逐个编译源文件做语法与类型检查（不链接），有错就退出非 0。
#
# 默认会挑本机最新的一份 iOS SDK（含 iOS 26 时才有液态玻璃相关的可用性检查）。
#   SDK=/path/to/iPhoneOS26.5.sdk bash scripts/check.sh
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MINIOS="${MINIOS:-15.0}"

pick_sdk() {
  if [ -n "${SDK:-}" ]; then printf '%s\n' "$SDK"; return; fi
  local best="" bestver=""
  for r in "$HOME/sdk26" "$HOME/sdks" "$HOME/theos/sdks"; do
    [ -d "$r" ] || continue
    for d in "$r"/iPhoneOS*.sdk; do
      [ -d "$d" ] || continue
      local v
      v=$(basename "$d" | sed -E 's/^iPhoneOS(.*)\.sdk$/\1/')
      if [ -z "$bestver" ] || [ "$(printf '%s\n%s\n' "$bestver" "$v" | sort -V | tail -1)" = "$v" ]; then
        best="$d"; bestver="$v"
      fi
    done
  done
  printf '%s\n' "$best"
}

SDK="$(pick_sdk)"
[ -n "$SDK" ] && [ -d "$SDK" ] || { echo "找不到 iOS SDK（可用 SDK=... 指定）" >&2; exit 1; }

FLAGS=(-isysroot "$SDK")
for d in System/Library/Frameworks System/Library/PrivateFrameworks System/Library/SubFrameworks; do
  [ -d "$SDK/$d" ] && FLAGS+=(-iframework "$SDK/$d")
done

OUT="$(mktemp -d)"
fail=0
echo "SDK: $SDK"
for f in "$ROOT"/Sudoku/*.m; do
    printf -- '--- %s\n' "$(basename "$f")"
    clang -target "arm64-apple-ios$MINIOS" "${FLAGS[@]}" -fobjc-arc -O2 \
          -Wall -Wextra -Wno-unused-parameter -Wno-unused-function \
          -I"$ROOT/Sudoku" -c "$f" -o "$OUT/$(basename "$f" .m).o" || fail=1
done
rm -rf "$OUT"
[ $fail -eq 0 ] && echo "全部通过" || echo "有错误"
exit $fail
