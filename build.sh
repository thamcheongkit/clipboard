#!/bin/bash
# Builds Clipboard.app and Clipboard.dmg. Requires macOS with Xcode command line tools.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf build && mkdir -p build/Clipboard.app/Contents/MacOS build/dmg
swiftc -O Sources/main.swift -o build/Clipboard.app/Contents/MacOS/Clipboard
cp Info.plist build/Clipboard.app/Contents/Info.plist
codesign --force --sign - build/Clipboard.app
cp -R build/Clipboard.app build/dmg/
ln -s /Applications build/dmg/Applications
hdiutil create -volname Clipboard -srcfolder build/dmg -ov -format UDZO build/Clipboard.dmg
echo "Created build/Clipboard.dmg"
