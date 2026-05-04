#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE_DIR="$(cd "$ROOT_DIR/.." && pwd)"
APP_NAME="MacmonBar"
APP_DIR="$ROOT_DIR/dist/$APP_NAME.app"
SWIFT_BINARY="$ROOT_DIR/.build/release/$APP_NAME"
RUNTIME_DIR="$WORKSPACE_DIR/MacmonBarRuntime"
MACMON_BINARY="$RUNTIME_DIR/target/release/macmon"
APP_ICON="$ROOT_DIR/Resources/AppIcon.icns"
LEGAL_DIR="$APP_DIR/Contents/Resources/Legal"

export CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/clang-module-cache"

swift build --package-path "$ROOT_DIR" -c release
cargo build --manifest-path "$RUNTIME_DIR/Cargo.toml" --release

if [[ ! -x "$SWIFT_BINARY" ]]; then
  echo "Missing Swift binary: $SWIFT_BINARY" >&2
  exit 1
fi

if [[ ! -x "$MACMON_BINARY" ]]; then
  echo "Missing macmon binary: $MACMON_BINARY" >&2
  exit 1
fi

if [[ ! -f "$APP_ICON" ]]; then
  echo "Missing app icon: $APP_ICON" >&2
  echo "Run: make icon" >&2
  exit 1
fi

BUILD_NUMBER="$("$ROOT_DIR/Scripts/bump-build-number.sh")"
echo "Bumped CFBundleVersion to $BUILD_NUMBER" >&2

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources/bin" "$LEGAL_DIR"

cp "$ROOT_DIR/Support/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$SWIFT_BINARY" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$MACMON_BINARY" "$APP_DIR/Contents/Resources/bin/macmon"
cp "$APP_ICON" "$APP_DIR/Contents/Resources/AppIcon.icns"
cp "$WORKSPACE_DIR/LICENSE" "$LEGAL_DIR/MacmonBar-LICENSE.txt"
cp "$WORKSPACE_DIR/THIRD_PARTY_NOTICES.md" "$LEGAL_DIR/THIRD_PARTY_NOTICES.md"
cp "$RUNTIME_DIR/LICENSE" "$LEGAL_DIR/macmon-LICENSE.txt"

chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"
chmod +x "$APP_DIR/Contents/Resources/bin/macmon"

echo "$APP_DIR"
