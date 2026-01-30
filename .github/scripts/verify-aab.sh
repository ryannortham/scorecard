#!/bin/bash
set -e

# Verify AAB file exists and check size
# Usage: ./verify-aab.sh <aab_path>

AAB_PATH=${1:-"build/app/outputs/bundle/release/app-release.aab"}

if [ ! -f "$AAB_PATH" ]; then
  echo "❌ AAB file not found at: $AAB_PATH"
  exit 1
fi

AAB_SIZE=$(stat -c%s "$AAB_PATH" 2>/dev/null || stat -f%z "$AAB_PATH")
echo "📦 AAB size: ${AAB_SIZE} bytes"

if [ "$AAB_SIZE" -lt 1000000 ]; then
  echo "⚠️ Warning: AAB file seems small (< 1MB)"
  echo "   This may indicate a build issue"
fi

echo "✅ AAB verification passed"
