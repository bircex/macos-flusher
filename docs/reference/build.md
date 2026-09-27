# Build from source

The app is a Swift package with no dependencies. A build takes about a minute.

## Requirements

- macOS 13 or newer
- Xcode Command Line Tools

```sh
xcode-select --install
```

## Build and run

```sh
git clone https://github.com/bircex/macos-flusher.git
cd macos-flusher
make run
```

`make run` builds the app, creates `dist/MacOS Flusher.app` and opens it.

## Make targets

| Target | Does |
| --- | --- |
| `make build` | Compiles the release binary |
| `make bundle` | Builds and creates the signed app bundle in `dist/` |
| `make run` | Bundles and opens the app |
| `make install` | Bundles and copies the app into `/Applications` |
| `make uninstall` | Removes the app from `/Applications` |
| `make package` | Bundles and creates the DMG, the ZIP and `SHA256SUMS` in `dist/` |
| `make icon` | Regenerates the app icon from `Tools/make-icon.swift` |
| `make clean` | Deletes `.build` and `dist` |

## Build options

| Variable | Default | Meaning |
| --- | --- | --- |
| `ARCHS` | Architecture of your Mac | Architectures to build, `arm64`, `x86_64` or both |
| `VERSION` | Not set | Version written into the bundle |
| `INSTALL_DIR` | `/Applications` | Target of `make install` and `make uninstall` |

A universal build with a version, the same way the release pipeline does it:

```sh
make package ARCHS="arm64 x86_64" VERSION=2026.9.0
```

## Project layout

| Path | Contains |
| --- | --- |
| `Sources/MacOSFlusher/Catalog.swift` | The list of caches |
| `Sources/MacOSFlusher/Store.swift` | Scan, flush and disk analysis |
| `Sources/MacOSFlusher/Locations.swift` | Rows of the location chart |
| `Sources/MacOSFlusher/Shell.swift` | Running `du` and cleanup commands |
| `Sources/MacOSFlusher/ContentView.swift` | Window, list, bars and activity log |
| `Sources/MacOSFlusher/Charts.swift` | Donut, tiles and the two charts |
| `docs/` | This site |
| `.github/workflows/` | The build, release and docs pipelines |

## Add a cache

Add one `CacheItem` to a group in `Catalog.swift`.

A folder cache:

```swift
CacheItem("uv", "uv cache", ["~/.cache/uv"]),
```

A cache that is cleaned by a command and needs its tool:

```swift
CacheItem("go-build", "Go build cache", ["~/Library/Caches/go-build"],
          flush: .command("go clean -cache"), requires: "go"),
```

| Field | Meaning |
| --- | --- |
| First value | Unique id |
| Second value | Name shown in the app |
| Third value | Folders to measure. `~` and `*` are supported. |
| `detail` | Text under the name. Defaults to the folders. |
| `sizeCommand` | Command that prints the size, for caches that are not folders |
| `flush` | `.removePaths` to empty the folders, or `.command("...")` to run a command |
| `requires` | Tool that must be installed for the cache to be available |
| `defaultOn` | `false` for caches that are slow to rebuild or hold user data |

Add the new cache to [What gets cleaned](/reference/catalog) in the same pull request.

## Work on this site

The documentation is built with VitePress and needs Node.js.

```sh
cd docs
npm install
npm run dev
```

`npm run build` creates the static site in `docs/.vitepress/dist`.

## Contribute

1. Create a branch and make the change.
2. Open a pull request. The `build` workflow must pass.
3. After the merge, the `release` workflow publishes a new version if the app changed.
