#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE_DIR="$(cd "$ROOT_DIR/.." && pwd)"
APP_NAME="MacmonBar"
APP_DIR="$ROOT_DIR/dist/$APP_NAME.app"
SWIFT_BINARY="$ROOT_DIR/.build/release/$APP_NAME"
MACMON_BINARY="$WORKSPACE_DIR/macmon/target/release/macmon"

export CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/clang-module-cache"

swift build --package-path "$ROOT_DIR" -c release
cargo build --manifest-path "$WORKSPACE_DIR/macmon/Cargo.toml" --release

if [[ ! -x "$SWIFT_BINARY" ]]; then
  echo "Missing Swift binary: $SWIFT_BINARY" >&2
  exit 1
fi

if [[ ! -x "$MACMON_BINARY" ]]; then
  echo "Missing macmon binary: $MACMON_BINARY" >&2
  exit 1
fi

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources/bin"

cp "$ROOT_DIR/Support/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$SWIFT_BINARY" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$MACMON_BINARY" "$APP_DIR/Contents/Resources/bin/macmon"

chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"
chmod +x "$APP_DIR/Contents/Resources/bin/macmon"

echo "$APP_DIR"
