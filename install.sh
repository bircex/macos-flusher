#!/bin/bash
set -euo pipefail

REPO="https://github.com/bircex/macos-flusher"
APP="MacOS Flusher"
INSTALL_DIR="${INSTALL_DIR:-/Applications}"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "MacOS Flusher only runs on macOS." >&2
    exit 1
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "Downloading the latest release..."
if curl -fsSL "$REPO/releases/latest/download/MacOS-Flusher.zip" -o "$WORK/MacOS-Flusher.zip" &&
    curl -fsSL "$REPO/releases/latest/download/SHA256SUMS" -o "$WORK/SHA256SUMS"; then
    (cd "$WORK" && grep " MacOS-Flusher.zip$" SHA256SUMS | shasum -a 256 -c - >/dev/null)
    ditto -x -k "$WORK/MacOS-Flusher.zip" "$WORK"
else
    echo "No release to download, building from source..."
    if ! xcode-select -p >/dev/null 2>&1; then
        echo "Xcode Command Line Tools are required. Starting the installer..."
        xcode-select --install || true
        echo "Re-run this script after the installation finishes." >&2
        exit 1
    fi
    git clone --quiet --depth 1 "$REPO.git" "$WORK/src"
    make -C "$WORK/src" bundle >/dev/null
    mv "$WORK/src/dist/$APP.app" "$WORK/"
fi

rm -rf "$INSTALL_DIR/$APP.app"
cp -R "$WORK/$APP.app" "$INSTALL_DIR/"
echo "Installed $INSTALL_DIR/$APP.app"
open "$INSTALL_DIR/$APP.app"
