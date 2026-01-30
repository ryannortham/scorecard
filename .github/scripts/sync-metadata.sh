#!/bin/bash
set -e

# Sync shared metadata to Fastlane directory structure
# Usage: ./sync-metadata.sh

METADATA_SRC="metadata/en-AU"
FASTLANE_DEST="android/fastlane/metadata/android/en-AU"

echo "📋 Syncing metadata from $METADATA_SRC to $FASTLANE_DEST"

# Create directory structure
mkdir -p "$FASTLANE_DEST/images/phoneScreenshots"
mkdir -p "$FASTLANE_DEST/changelogs"

# Copy metadata files
cp "$METADATA_SRC/title.txt" "$FASTLANE_DEST/title.txt"
cp "$METADATA_SRC/short_description.txt" "$FASTLANE_DEST/short_description.txt"
cp "$METADATA_SRC/description.txt" "$FASTLANE_DEST/full_description.txt"
cp "$METADATA_SRC/release_notes.txt" "$FASTLANE_DEST/changelogs/default.txt"

# Copy screenshots
cp metadata/screenshots/*.png "$FASTLANE_DEST/images/phoneScreenshots/"

echo "✅ Synced Android metadata"
ls -la "$FASTLANE_DEST"
