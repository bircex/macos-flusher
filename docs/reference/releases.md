# Versions and releases

MacOS Flusher uses calendar versioning. A version tells you when the build was made, not how big the change was.

## Version format

```text
YYYY.M.PATCH
```

| Part | Meaning | Example |
| --- | --- | --- |
| `YYYY` | Year of the release | `2026` |
| `M` | Month of the release, without a leading zero | `9` |
| `PATCH` | Number of the release within that month, starting at 0 | `0` |

Examples:

| Version | Meaning |
| --- | --- |
| `2026.9.0` | First release in September 2026 |
| `2026.9.3` | Fourth release in September 2026 |
| `2026.10.0` | First release in October 2026 |

Git tags carry a `v` in front, for example `v2026.9.0`.

## Where to see the version

- In the app: **MacOS Flusher > About MacOS Flusher**
- On GitHub: the [releases page](https://github.com/bircex/macos-flusher/releases)

Builds made from source without a version show `0.1.0`.

## What a release contains

| File | Purpose |
| --- | --- |
| `MacOS-Flusher.dmg` | Disk image for installing by hand |
| `MacOS-Flusher.zip` | The app bundle, used by the install script |
| `SHA256SUMS` | Checksums of the two files above |

File names are the same in every release, so these links always point to the newest version:

```text
https://github.com/bircex/macos-flusher/releases/latest/download/MacOS-Flusher.dmg
https://github.com/bircex/macos-flusher/releases/latest/download/MacOS-Flusher.zip
https://github.com/bircex/macos-flusher/releases/latest/download/SHA256SUMS
```

Every release is a universal binary for Apple Silicon and Intel and needs macOS 13 or newer.

## How a release is made

Releases are made by the `release` workflow on GitHub Actions. Nobody builds them by hand.

1. A change to the app is merged into `main`.
2. The workflow picks the next version: the current year and month, and the next free patch number.
3. It builds the app for both architectures and writes the version into the bundle.
4. It packages the DMG and the ZIP and calculates the checksums.
5. It creates the tag and the GitHub release with notes generated from the merged pull requests.

The workflow starts only when one of these changes:

```text
Sources/
Resources/
Info.plist
Package.swift
Makefile
```

Changes to the documentation or the README do not create a release. A release can also be started by hand from the **Actions** tab.

## Pipelines

| Workflow | Runs on | Does |
| --- | --- | --- |
| `build` | Every pull request and every push to `main` | Builds and packages the app, checks both architectures and the checksums |
| `release` | Push to `main` that changes the app | Picks the version and publishes the release |
| `docs` | Push to `main` that changes `docs/` | Builds this site and publishes it to GitHub Pages |
