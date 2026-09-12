#!/bin/bash
set -euo pipefail

REPO="https://github.com/recepkizilarslan/macos-flusher.git"
APP="MacOS Flusher"
INSTALL_DIR="${INSTALL_DIR:-/Applications}"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "MacOS Flusher only runs on macOS." >&2
    exit 1
fi

if ! xcode-select -p >/dev/null 2>&1; then
    echo "Xcode Command Line Tools are required. Starting the installer..."
    xcode-select --install || true
    echo "Re-run this script after the installation finishes." >&2
    exit 1
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "Downloading source..."
git clone --quiet --depth 1 "$REPO" "$WORK/src"

echo "Building (this takes about a minute the first time)..."
make -C "$WORK/src" bundle >/dev/null

rm -rf "$INSTALL_DIR/$APP.app"
cp -R "$WORK/src/dist/$APP.app" "$INSTALL_DIR/"
echo "Installed $INSTALL_DIR/$APP.app"
open "$INSTALL_DIR/$APP.app"
