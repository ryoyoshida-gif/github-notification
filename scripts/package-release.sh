#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/build-app.sh
version="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Resources/Info.plist)"
architecture="$(lipo -archs 'dist/GitHub Signal.app/Contents/MacOS/GitHubSignal')"
archive="GitHubSignal-${version}-macos-${architecture}.zip"
ditto -c -k --sequesterRsrc --keepParent 'dist/GitHub Signal.app' "dist/$archive"
(cd dist && shasum -a 256 "$archive" > "${archive}.sha256")
printf 'Release archive: %s/dist/%s\n' "$PWD" "$archive"
