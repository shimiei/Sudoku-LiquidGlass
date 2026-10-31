#!/usr/bin/env bash
# Build an unsigned .ipa from the Objective-C sources (no Xcode, no Mac, no signing).
#
#   ./scripts/build-ios.sh              # uses ~/ios-ipa-kit/build-objc.sh
#   MINIOS=15.0 ./scripts/build-ios.sh
#
# Requires: clang, ld64.lld, an iPhoneOS SDK (theos/sdks), zip.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPNAME="Sudoku"
BUNDLEID="com.shimiei.sudoku"
MINIOS="${MINIOS:-15.0}"

if [ -x "$HOME/ios-ipa-kit/build-objc.sh" ]; then
    bash "$HOME/ios-ipa-kit/build-objc.sh" "$ROOT/Sudoku" "$APPNAME" "$BUNDLEID" "$MINIOS"
    cp -f "${OUT:-$HOME/ios-ipa-kit/out}/$APPNAME-unsigned.ipa" "$ROOT/$APPNAME-unsigned.ipa"
    echo "OK -> $ROOT/$APPNAME-unsigned.ipa"
    exit 0
fi

# ---- Standalone fallback: same pipeline, spelled out -------------------------
SDK="${SDK:-$(ls -1d "${SDKROOT:-$HOME/theos/sdks}"/iPhoneOS*.sdk | sort -V | tail -1)}"
LD64="$(command -v ld64.lld-18 || command -v ld64.lld-19 || command -v ld64.lld)"
BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT

i=0
OBJS=()
for f in "$ROOT"/Sudoku/*.m; do
    o="$BUILD/obj_$i.o"; i=$((i+1))
    clang -target "arm64-apple-ios$MINIOS" -isysroot "$SDK" -fobjc-arc -O2 \
          -I"$ROOT/Sudoku" -c "$f" -o "$o"
    OBJS+=("$o")
done

APP="$BUILD/Sudoku.app"
mkdir -p "$APP"
"$LD64" -arch arm64 -platform_version ios "$MINIOS" \
    "$(basename "$SDK" | sed -E 's/^iPhoneOS(.*)\.sdk$/\1/')" \
    -syslibroot "$SDK" -L"$SDK/usr/lib" -lSystem \
    -framework UIKit -framework Foundation -framework CoreGraphics -framework CoreFoundation \
    -framework QuartzCore \
    -o "$APP/Sudoku" "${OBJS[@]}"

cp "$ROOT/Sudoku/Info.plist" "$APP/Info.plist"
printf 'APPL????' > "$APP/PkgInfo"
mkdir -p "$BUILD/Payload"
mv "$APP" "$BUILD/Payload/"
( cd "$BUILD" && zip -qry "Sudoku-unsigned.ipa" Payload )
cp "$BUILD/Sudoku-unsigned.ipa" "$ROOT/Sudoku-unsigned.ipa"
echo "OK -> $ROOT/Sudoku-unsigned.ipa"
