#!/bin/bash
set -e

# Extract version from pubspec.yaml and generate version name/code
# Usage: ./extract-version.sh <run_number> <output_file>

RUN_NUMBER=${1:-0}
OUTPUT_FILE=${2:-$GITHUB_OUTPUT}

# Extract version from pubspec and strip trailing .0 (e.g., "1.0.0" -> "1.0")
PUBSPEC_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | tr -d ' ')
BASE_VERSION=$(echo "$PUBSPEC_VERSION" | sed 's/\.0$//')

# Offset ensures version codes continue above historical max (was 293)
VERSION_CODE=$((200 + RUN_NUMBER))
VERSION_NAME="${BASE_VERSION}.${VERSION_CODE}"

# Output for GitHub Actions
echo "version_name=$VERSION_NAME" >> "$OUTPUT_FILE"
echo "version_code=$VERSION_CODE" >> "$OUTPUT_FILE"

# Display for logs
echo "📱 Version: $VERSION_NAME (Code: $VERSION_CODE)"
