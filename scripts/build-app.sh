#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export CLANG_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/github-signal-clang-cache"
swift build -c release --disable-sandbox --cache-path .build/cache --config-path .build/config --security-path .build/security
bin_dir="$(swift build -c release --show-bin-path --disable-sandbox --cache-path .build/cache --config-path .build/config --security-path .build/security)"
app="dist/GitHub Signal.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin_dir/GitHubSignal" "$app/Contents/MacOS/GitHubSignal"
cp Resources/Info.plist "$app/Contents/Info.plist"
cp Resources/AppIcon.icns "$app/Contents/Resources/AppIcon.icns"
cp Resources/Octicons-LICENSE "$app/Contents/Resources/Octicons-LICENSE"
codesign --force --sign - "$app"
printf 'Built: %s/%s\n' "$PWD" "$app"
