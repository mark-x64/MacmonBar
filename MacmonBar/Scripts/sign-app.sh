#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="MacmonBar"
APP_DIR="${1:-$ROOT_DIR/dist/$APP_NAME.app}"
MACMON_BINARY="$APP_DIR/Contents/Resources/bin/macmon"

if [[ -z "${DEVELOPER_ID_APPLICATION:-}" ]]; then
  cat >&2 <<'EOF'
Missing DEVELOPER_ID_APPLICATION.

Example:
  export DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name (TEAMID)"
  ./Scripts/sign-app.sh
EOF
  exit 64
fi

if [[ ! -d "$APP_DIR" ]]; then
  echo "Missing app bundle: $APP_DIR" >&2
  exit 66
fi

if [[ ! -x "$MACMON_BINARY" ]]; then
  echo "Missing bundled macmon binary: $MACMON_BINARY" >&2
  exit 66
fi

codesign \
  --force \
  --timestamp \
  --options runtime \
  --sign "$DEVELOPER_ID_APPLICATION" \
  "$MACMON_BINARY"

codesign \
  --force \
  --timestamp \
  --options runtime \
  --sign "$DEVELOPER_ID_APPLICATION" \
  "$APP_DIR"

codesign --verify --deep --strict --verbose=2 "$APP_DIR"
