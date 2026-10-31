#!/usr/bin/env bash
# 源码 → iOS .app → 未签名 .ipa（Objective-C，不需要 Mac、不需要签名）
#
# 用法:  bash scripts/build-ios.sh
# 环境:
#   SDK=/path/to/iPhoneOS26.5.sdk   指定 SDK（默认自动找最新的 iPhoneOS 26.x / 18.x / theos）
#   MINIOS=15.0                    最低系统版本
#   ARCH=arm64
#   OUT=out                        ipa 输出目录
#
# 重要：用 iOS 26 SDK 编译出来的包，系统才会按 iOS 26 的新设计（Liquid Glass）渲染
# 导航栏、按钮、弹窗等系统组件。用旧 SDK 编译 = 停在旧外观。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/Sudoku"
APPNAME="Sudoku"
BUNDLEID="com.shimiei.sudoku"
MINIOS="${MINIOS:-15.0}"
ARCH="${ARCH:-arm64}"
OUT="${OUT:-$ROOT/out}"

# ---- 1. 选 SDK -------------------------------------------------------------
pick_sdk() {
  if [ -n "${SDK:-}" ]; then printf '%s\n' "$SDK"; return; fi
  local roots=("$HOME/sdk26" "$HOME/sdks" "$HOME/theos/sdks")
  local best="" bestver=""
  for r in "${roots[@]}"; do
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
if [ -z "$SDK" ] || [ ! -d "$SDK" ]; then
  cat >&2 <<'EOF'
找不到 iOS SDK。任选一种装法：
  # theos 的公开 SDK（较旧，停留在旧外观）
  git clone --depth 1 https://github.com/theos/sdks.git ~/theos/sdks
  # 含 iOS 26 的镜像（只取头文件和 stub，约 310MB）
  git clone --filter=blob:none --sparse --depth 1 https://github.com/xybp888/iOS-SDKs.git ~/sdk26
  cd ~/sdk26 && git sparse-checkout set --no-cone \
      "/iPhoneOS26.5.sdk/usr/include/**" "/iPhoneOS26.5.sdk/usr/lib/**" \
      "/iPhoneOS26.5.sdk/System/Library/Frameworks/**" \
      "/iPhoneOS26.5.sdk/System/Library/SubFrameworks/**" \
      "/iPhoneOS26.5.sdk/SDKSettings.plist"
EOF
  exit 1
fi
SDKVER=$(basename "$SDK" | sed -E 's/^iPhoneOS(.*)\.sdk$/\1/')

# 搜索路径：UIKit 的公开头会 import UIUtilities（在 SubFrameworks），
# 少了这条 -F 就会报 'UIUtilities/UIDefines.h' file not found。
SDKFLAGS=(-isysroot "$SDK")
LINKF=()
for d in System/Library/Frameworks System/Library/PrivateFrameworks System/Library/SubFrameworks; do
  [ -d "$SDK/$d" ] || continue
  SDKFLAGS+=(-iframework "$SDK/$d")
  LINKF+=(-F"$SDK/$d")
done

LD64="${LD64:-}"
if [ -z "$LD64" ]; then
  for c in ld64.lld-18 ld64.lld-19 ld64.lld-17 ld64.lld; do
    command -v "$c" >/dev/null 2>&1 && { LD64="$c"; break; }
  done
fi
[ -n "$LD64" ] || { echo "找不到 ld64.lld（apt install lld）" >&2; exit 1; }

echo "== 构建 $APPNAME =="
echo "   SDK    : $SDK (iOS $SDKVER)"
echo "   链接器 : $(command -v "$LD64")"
echo "   目标   : $ARCH-apple-ios$MINIOS"

# ---- 2. 编译 ---------------------------------------------------------------
BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT
mapfile -t SOURCES < <(find "$SRC" -type f -name '*.m' -not -path '*/out/*' | sort)
[ "${#SOURCES[@]}" -gt 0 ] || { echo "没有 .m 源文件: $SRC" >&2; exit 1; }

OBJS=()
i=0
for s in "${SOURCES[@]}"; do
  o="$BUILD/o$i.o"; i=$((i+1))
  echo "   CC   $(basename "$s")"
  clang -target "$ARCH-apple-ios$MINIOS" "${SDKFLAGS[@]}" -fobjc-arc -O2 \
        -Wall -I"$SRC" -c "$s" -o "$o"
  OBJS+=("$o")
done

# ---- 3. 链接 ---------------------------------------------------------------
APP="$BUILD/Payload/$APPNAME.app"
mkdir -p "$APP"
echo "   LINK $APPNAME"
"$LD64" -arch "$ARCH" -platform_version ios "$MINIOS" "$SDKVER" \
  -syslibroot "$SDK" -L"$SDK/usr/lib" "${LINKF[@]}" \
  -lSystem \
  -framework UIKit -framework Foundation -framework CoreGraphics \
  -framework CoreFoundation -framework QuartzCore -framework AudioToolbox \
  -o "$APP/$APPNAME" "${OBJS[@]}"

# ---- 4. 资源 ---------------------------------------------------------------
# Resources/ 里既有 Info.plist 也有各尺寸图标，整体拷进去
cp -R "$SRC/Resources"/. "$APP"/
[ -f "$APP/Info.plist" ] || { echo "缺少 Info.plist" >&2; exit 1; }
printf 'APPL????' > "$APP/PkgInfo"
# 清掉可能混进来的签名残留
rm -rf "$APP/_CodeSignature" "$APP/embedded.mobileprovision" "$APP/SC_Info"

# ---- 5. 打 ipa -------------------------------------------------------------
mkdir -p "$OUT"
IPA="$OUT/$APPNAME-unsigned.ipa"
rm -f "$IPA"
(cd "$BUILD" && zip -qry "$IPA" "Payload")
cp -f "$IPA" "$ROOT/$APPNAME-unsigned.ipa"

echo "== 完成 =="
ls -l "$IPA" | awk '{print "   ipa: "$5" bytes  "$9}'
echo "OK -> $ROOT/$APPNAME-unsigned.ipa"
