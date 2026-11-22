#!/bin/sh
# Exports the Web build and zips it for itch.io: build/summonkey-web.zip
# Needs Godot's export templates installed (Editor > Manage Export Templates).
# Set GODOT to your Godot binary if it isn't the Steam install.
set -e
cd "$(dirname "$0")/.."
GODOT="${GODOT:-$HOME/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot}"
rm -rf build/web build/summonkey-web.zip
mkdir -p build/web
"$GODOT" --headless --path . --export-release "Web" build/web/index.html
(cd build/web && zip -qr ../summonkey-web.zip .)
echo "Ready to upload: build/summonkey-web.zip"
