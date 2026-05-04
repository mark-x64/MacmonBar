#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="MacmonBar"
APP_DIR="${1:-$ROOT_DIR/dist/$APP_NAME.app}"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT_DIR/Support/Info.plist")"
ZIP_PATH="${2:-$ROOT_DIR/dist/$APP_NAME-$VERSION.zip}"

if [[ ! -d "$APP_DIR" ]]; then
  echo "Missing app bundle: $APP_DIR" >&2
  exit 66
fi

rm -f "$ZIP_PATH" "$ZIP_PATH.sha256"

(
  cd "$(dirname "$APP_DIR")"
  ditto -c -k --keepParent "$(basename "$APP_DIR")" "$ZIP_PATH"
)

shasum -a 256 "$ZIP_PATH" > "$ZIP_PATH.sha256"

echo "$ZIP_PATH"
