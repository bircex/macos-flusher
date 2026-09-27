# Install

MacOS Flusher runs on macOS 13 Ventura or newer. The app is a universal binary, so the same download works on Apple Silicon and Intel Macs.

There are three ways to install it. Pick one.

| Method | Needs | First launch |
| --- | --- | --- |
| [Download the DMG](#download-the-dmg) | Nothing | macOS asks you to allow the app once |
| [Install with one command](#install-with-one-command) | Terminal | Opens right away |
| [Build from source](/reference/build) | Xcode Command Line Tools | Opens right away |

## Download the DMG

1. Download [MacOS-Flusher.dmg](https://github.com/bircex/macos-flusher/releases/latest/download/MacOS-Flusher.dmg).
2. Open the file and drag **MacOS Flusher** onto the **Applications** folder.
3. Open the app from Applications.

The app is not notarized by Apple, so macOS blocks it the first time you open a copy that was downloaded with a browser. [First launch](/guide/first-launch) shows how to allow it.

## Install with one command

```sh
curl -fsSL https://raw.githubusercontent.com/bircex/macos-flusher/main/install.sh | bash
```

The script does four things:

1. Downloads the latest release from GitHub.
2. Checks the download against the published SHA-256 checksum.
3. Copies `MacOS Flusher.app` into `/Applications`, replacing an older copy.
4. Opens the app.

Files downloaded with `curl` are not quarantined by macOS, so the app opens without the security prompt.

To install somewhere else, set `INSTALL_DIR`:

```sh
curl -fsSL https://raw.githubusercontent.com/bircex/macos-flusher/main/install.sh | INSTALL_DIR="$HOME/Applications" bash
```

If no release can be downloaded, the script builds the app from source instead. That path needs the Xcode Command Line Tools.

## Verify a download

Every release ships a `SHA256SUMS` file next to the DMG and the ZIP.

```sh
cd ~/Downloads
curl -fsSLO https://github.com/bircex/macos-flusher/releases/latest/download/SHA256SUMS
grep MacOS-Flusher.dmg SHA256SUMS | shasum -a 256 -c -
```

The command prints `MacOS-Flusher.dmg: OK` when the file is intact.

## Update

The app does not update itself. Install the new version the same way you installed the first one. The new copy replaces the old one.

The installed version is shown under **MacOS Flusher > About MacOS Flusher** in the menu bar. [Versions and releases](/reference/releases) explains how versions are numbered.

## Uninstall

1. Quit the app.
2. Delete `MacOS Flusher.app` from Applications.

The app keeps no data of its own. macOS stores the window position in one small file, which you can delete as well:

```sh
rm ~/Library/Preferences/com.recepkizilarslan.MacOSFlusher.plist
```
