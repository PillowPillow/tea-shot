#!/bin/bash
# Installs the latest TeaShot release: curl -fsSL https://raw.githubusercontent.com/PillowPillow/tea-shot/main/install.sh | bash
set -euo pipefail

URL="https://github.com/PillowPillow/tea-shot/releases/latest/download/TeaShot.zip"
BUNDLE_ID="io.github.pillowpillow.teashot"
REPO="PillowPillow/tea-shot"

fail() {
    echo "$1" >&2
    exit 1
}

# Wrapped in a function so a truncated download never runs a partial script.
main() {
    [[ "$(uname)" == "Darwin" ]] || fail "TeaShot runs on macOS only."
    (( $(sw_vers -productVersion | cut -d. -f1) >= 14 )) || fail "TeaShot needs macOS 14 Sonoma or later."
    [[ $EUID -ne 0 ]] || fail "Run the installer without sudo."

    local dest="/Applications"
    [[ -w "$dest" ]] || dest="$HOME/Applications"
    mkdir -p "$dest"

    work="$(mktemp -d)"
    trap 'rm -rf "$work"' EXIT

    echo "Downloading TeaShot…"
    curl -fL --proto '=https' --proto-redir '=https' --progress-bar "$URL" -o "$work/TeaShot.zip"

    # Ad-hoc signatures prove integrity only; the attestation proves the zip came from the release workflow.
    if command -v gh >/dev/null && gh auth status >/dev/null 2>&1 && gh attestation --help >/dev/null 2>&1; then
        local report
        report="$(gh attestation verify "$work/TeaShot.zip" --repo "$REPO" \
            --signer-workflow "$REPO/.github/workflows/release.yml" 2>&1)" || {
            echo "$report" >&2
            fail "Could not verify that the download is a TeaShot release build (see the error above). Nothing was installed."
        }
        echo "Provenance verified."
    else
        echo "Provenance not checked: install the GitHub CLI and sign in to verify the release build."
    fi

    ditto -x -k "$work/TeaShot.zip" "$work"

    local app="$work/TeaShot.app"
    codesign --verify --strict "$app" 2>/dev/null || fail "The downloaded app is damaged. Nothing was installed."
    [[ "$(defaults read "$app/Contents/Info" CFBundleIdentifier 2>/dev/null)" == "$BUNDLE_ID" ]] \
        || fail "The download is not TeaShot. Nothing was installed."

    if [[ -e "$dest/TeaShot.app" && ! -w "$dest/TeaShot.app" ]]; then
        fail "$dest/TeaShot.app belongs to another user. Delete it, then run the installer again."
    fi

    if pgrep -xqu "$EUID" TeaShot; then
        osascript -e 'quit app "TeaShot"' >/dev/null 2>&1 || pkill -xu "$EUID" TeaShot || true
        sleep 1
    fi

    rm -rf "$dest/TeaShot.app"
    ditto "$app" "$dest/TeaShot.app"
    # curl downloads carry no quarantine flag; clear it anyway in case the zip came from a browser.
    xattr -dr com.apple.quarantine "$dest/TeaShot.app" 2>/dev/null || true

    open "$dest/TeaShot.app"
    echo "TeaShot is installed in $dest. Look for the cup in your menu bar."
}

main "$@"
