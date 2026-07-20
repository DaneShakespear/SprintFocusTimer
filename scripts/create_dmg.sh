#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA_DIR="$ROOT_DIR/build/DerivedData"
DMG_ROOT="$ROOT_DIR/build/dmgroot"
DIST_DIR="$ROOT_DIR/dist"
APP_PATH="$DERIVED_DATA_DIR/Build/Products/Release/SprintFocusTimer.app"
DMG_PATH="$DIST_DIR/SprintFocusTimer.dmg"

cd "$ROOT_DIR"

xcodebuild \
  -project SprintFocusTimer.xcodeproj \
  -scheme SprintFocusTimer \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA_DIR" \
  CODE_SIGNING_ALLOWED=NO \
  build

rm -rf "$DMG_ROOT" "$DIST_DIR"
mkdir -p "$DMG_ROOT" "$DIST_DIR"

cp -R "$APP_PATH" "$DMG_ROOT/"
cp "$ROOT_DIR/Distribution/Install Instructions.txt" "$DMG_ROOT/"
ln -s /Applications "$DMG_ROOT/Applications"
xattr -cr "$DMG_ROOT/SprintFocusTimer.app"

hdiutil create \
  -volname SprintFocusTimer \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "Created $DMG_PATH"
