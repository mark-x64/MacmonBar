#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="MacmonBar"
APP_DIR="${1:-$ROOT_DIR/dist/$APP_NAME.app}"
UPLOAD_ZIP="$ROOT_DIR/dist/$APP_NAME-notary-upload.zip"

if [[ -z "${NOTARY_PROFILE:-}" ]]; then
  cat >&2 <<'EOF'
Missing NOTARY_PROFILE.

Create one first:
  xcrun notarytool store-credentials macmonbar-notary

Then run:
  export NOTARY_PROFILE="macmonbar-notary"
  ./Scripts/notarize-app.sh
EOF
  exit 64
fi

if [[ ! -d "$APP_DIR" ]]; then
  echo "Missing app bundle: $APP_DIR" >&2
  exit 66
fi

rm -f "$UPLOAD_ZIP"

(
  cd "$(dirname "$APP_DIR")"
  ditto -c -k --keepParent "$(basename "$APP_DIR")" "$UPLOAD_ZIP"
)

xcrun notarytool submit "$UPLOAD_ZIP" \
  --keychain-profile "$NOTARY_PROFILE" \
  --wait

xcrun stapler staple "$APP_DIR"
xcrun stapler validate "$APP_DIR"

"$ROOT_DIR/Scripts/create-zip.sh" "$APP_DIR"
