#!/bin/bash
# Installs the latest TeaShot release: curl -fsSL https://raw.githubusercontent.com/PillowPillow/tea-shot/main/install.sh | bash
set -euo pipefail

URL="${TEASHOT_URL:-https://github.com/PillowPillow/tea-shot/releases/latest/download/TeaShot.zip}"

if [[ "$(uname)" != "Darwin" ]] || (( $(sw_vers -productVersion | cut -d. -f1) < 14 )); then
    echo "TeaShot needs macOS 14 Sonoma or later." >&2
    exit 1
fi

DEST="/Applications"
[[ -w "$DEST" ]] || DEST="$HOME/Applications"
mkdir -p "$DEST"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

echo "Downloading TeaShot…"
curl -fL --progress-bar "$URL" -o "$work/TeaShot.zip"
ditto -x -k "$work/TeaShot.zip" "$work"

if pgrep -xq TeaShot; then
    osascript -e 'quit app "TeaShot"' >/dev/null 2>&1 || pkill -x TeaShot || true
    sleep 1
fi

rm -rf "$DEST/TeaShot.app"
ditto "$work/TeaShot.app" "$DEST/TeaShot.app"
# curl downloads carry no quarantine flag; clear it anyway in case the zip came from a browser.
xattr -dr com.apple.quarantine "$DEST/TeaShot.app" 2>/dev/null || true

open "$DEST/TeaShot.app"
echo "TeaShot is installed in $DEST. Look for the cup in your menu bar."
