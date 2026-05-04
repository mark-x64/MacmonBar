#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INFO_PLIST="$ROOT_DIR/Support/Info.plist"
CURRENT_BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$INFO_PLIST")"

if [[ ! "$CURRENT_BUILD" =~ ^[0-9]+$ ]]; then
  echo "CFBundleVersion must be a whole number, got: $CURRENT_BUILD" >&2
  exit 65
fi

NEXT_BUILD=$((CURRENT_BUILD + 1))
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEXT_BUILD" "$INFO_PLIST"
echo "$NEXT_BUILD"
