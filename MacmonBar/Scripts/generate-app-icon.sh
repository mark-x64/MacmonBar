#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICONSET="$ROOT_DIR/Resources/AppIcon.iconset"
OUTPUT_ICNS="$ROOT_DIR/Resources/AppIcon.icns"

export CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/clang-module-cache"

"$ROOT_DIR/Scripts/generate-app-icon.swift"

echo "$OUTPUT_ICNS"
