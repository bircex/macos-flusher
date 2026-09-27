# What gets cleaned

The app knows 88 caches in 14 groups. This page lists every one of them with the exact folders it empties or the exact command it runs.

## How to read the tables

| Column | Meaning |
| --- | --- |
| Cache | The name shown in the app |
| Removes | The folders that are emptied, or the command that is run |
| Selected | Whether the cache is selected when the app opens |

How a cache is removed depends on its entry:

- **A folder**: everything inside the folder is deleted. The folder itself stays.
- **A pattern with `*`**: every file or folder that matches is deleted.
- **A command**: the app runs the tool's own cleanup command and deletes nothing itself.

Caches that need a tool are greyed out when the tool is not installed.

## JavaScript / TypeScript

| Cache | Removes | Selected |
| --- | --- | --- |
| npm cache | `npm cache clean --force` | Yes |
| Yarn cache | `~/Library/Caches/Yarn`<br>`~/.yarn/cache`<br>`~/.yarn/berry/cache` | Yes |
| pnpm store | `~/Library/pnpm/store`<br>`~/Library/Caches/pnpm`<br>`~/.pnpm-store` | Yes |
| Bun install cache | `~/.bun/install/cache` | Yes |
| Deno cache | `~/Library/Caches/deno` | Yes |
| Corepack cache | `~/.cache/node/corepack` | Yes |
| nvm download cache | `~/.nvm/.cache` | Yes |
| node-gyp headers | `~/Library/Caches/node-gyp`<br>`~/.node-gyp` | Yes |
| Electron downloads | `~/Library/Caches/electron`<br>`~/.electron`<br>`~/Library/Caches/electron-builder` | Yes |
| Turborepo cache | `~/Library/Caches/turborepo`<br>`~/.turbo` | Yes |

## Python

| Cache | Removes | Selected |
| --- | --- | --- |
| pip cache | `~/Library/Caches/pip` | Yes |
| uv cache | `~/.cache/uv` | Yes |
| Poetry cache | `~/Library/Caches/pypoetry` | Yes |
| Pipenv cache | `~/Library/Caches/pipenv` | Yes |
| pipx cache | `~/.local/pipx/.cache` | Yes |
| Conda package cache | `~/miniconda3/pkgs`<br>`~/anaconda3/pkgs`<br>`~/miniforge3/pkgs`<br>`~/.conda/pkgs` | Yes |
| Ruff cache | `~/Library/Caches/ruff`<br>`~/.cache/ruff` | Yes |
| pre-commit environments | `~/.cache/pre-commit` | Yes |
| Hugging Face hub | `~/.cache/huggingface` | No |
| PyTorch hub | `~/.cache/torch` | No |

## Go

| Cache | Removes | Selected |
| --- | --- | --- |
| Go build cache | `go clean -cache` | Yes |
| Go module cache | `go clean -modcache` | No |
| Go tools | `~/Library/Caches/gopls`<br>`~/Library/Caches/goimports`<br>`~/Library/Caches/golangci-lint`<br>`~/Library/Caches/staticcheck` | Yes |

## Rust

| Cache | Removes | Selected |
| --- | --- | --- |
| Cargo registry & git | `~/.cargo/registry/cache`<br>`~/.cargo/registry/src`<br>`~/.cargo/git` | Yes |
| rustup downloads | `~/.rustup/downloads`<br>`~/.rustup/tmp` | Yes |
| sccache | `~/Library/Caches/Mozilla.sccache`<br>`~/.cache/sccache` | Yes |

## JVM (Java, Kotlin, Scala, Clojure, Android)

| Cache | Removes | Selected |
| --- | --- | --- |
| Gradle caches | `~/.gradle/caches`<br>`~/.gradle/daemon` | Yes |
| Maven repository | `~/.m2/repository` | No |
| Coursier / sbt cache | `~/Library/Caches/Coursier`<br>`~/.cache/coursier`<br>`~/.sbt/boot`<br>`~/.ivy2/cache` | Yes |
| Kotlin daemon & konan | `~/.kotlin`<br>`~/.konan/cache` | Yes |
| Android build cache | `~/.android/cache`<br>`~/.android/build-cache` | Yes |
| Bazel cache | `~/.cache/bazel`<br>`/private/var/tmp/_bazel_*` | No |

## .NET

| Cache | Removes | Selected |
| --- | --- | --- |
| NuGet packages | `~/.nuget/packages` | No |
| NuGet HTTP cache | `~/.local/share/NuGet/http-cache`<br>`~/.nuget/v3-cache` | Yes |

## Swift / Objective-C

| Cache | Removes | Selected |
| --- | --- | --- |
| Xcode DerivedData | `~/Library/Developer/Xcode/DerivedData` | Yes |
| Xcode iOS DeviceSupport | `~/Library/Developer/Xcode/iOS DeviceSupport` | No |
| iOS Simulator caches | `~/Library/Developer/CoreSimulator/Caches` | Yes |
| Swift PM cache | `~/Library/Caches/org.swift.swiftpm` | Yes |
| CocoaPods cache | `~/Library/Caches/CocoaPods` | Yes |
| Carthage cache | `~/Library/Caches/carthage`<br>`~/Library/Caches/org.carthage.CarthageKit` | Yes |

## Ruby / PHP / Perl / Lua

| Cache | Removes | Selected |
| --- | --- | --- |
| RubyGems & Bundler cache | `~/.gem/specs`<br>`~/.gem/ruby/*/cache`<br>`~/.bundle/cache` | Yes |
| Composer cache | `~/.composer/cache`<br>`~/Library/Caches/composer`<br>`~/.cache/composer` | Yes |
| CPAN build & sources | `~/.cpan/build`<br>`~/.cpan/sources`<br>`~/.cpanm/work` | Yes |
| LuaRocks cache | `~/.cache/luarocks` | Yes |

## Elixir / Erlang / Haskell / OCaml

| Cache | Removes | Selected |
| --- | --- | --- |
| Hex package cache | `~/.hex`<br>`~/.cache/hex` | Yes |
| rebar3 cache | `~/.cache/rebar3` | Yes |
| Cabal packages | `~/.cabal/packages`<br>`~/.cache/cabal` | Yes |
| Stack indices | `~/.stack/indices`<br>`~/.stack/pantry` | No |
| opam download cache | `~/.opam/download-cache` | Yes |

## C / C++

| Cache | Removes | Selected |
| --- | --- | --- |
| ccache | `~/Library/Caches/ccache`<br>`~/.ccache`<br>`~/.cache/ccache` | Yes |
| Conan packages | `~/.conan2/p`<br>`~/.conan/data` | Yes |
| vcpkg cache | `~/.cache/vcpkg`<br>`~/Library/Caches/vcpkg` | Yes |

## Dart, Zig, Nim, Julia, R, Crystal, D

| Cache | Removes | Selected |
| --- | --- | --- |
| Dart / Flutter pub cache | `~/.pub-cache` | No |
| Zig cache | `~/.cache/zig` | Yes |
| Nim cache | `~/.cache/nim`<br>`~/.nimble/pkgcache` | Yes |
| Julia compiled cache | `~/.julia/compiled`<br>`~/.julia/logs` | Yes |
| R cache | `~/Library/Caches/org.R-project.R`<br>`~/.cache/R` | Yes |
| Crystal cache | `~/.cache/crystal` | Yes |
| D dub packages | `~/.dub/packages` | Yes |

## Containers & VMs

| Cache | Removes | Selected |
| --- | --- | --- |
| Docker build cache | `docker builder prune -af` | Yes |
| Docker dangling images | `docker image prune -f` | Yes |
| Docker unused images (all) | `docker image prune -af` | No |
| Docker anonymous unused volumes | `docker volume prune -f` | Yes |
| Docker stopped containers | `docker container prune -f` | No |
| Podman unused data | `podman system prune -af` | No |
| minikube cache | `~/.minikube/cache` | No |
| Vagrant boxes | `~/.vagrant.d/boxes` | No |
| Lima / Colima cache | `~/Library/Caches/lima` | No |

::: info Named Docker volumes are kept
`docker volume prune -f` removes only anonymous volumes that no container uses. Volumes with a name are never removed.
:::

## IDEs & dev tools

| Cache | Removes | Selected |
| --- | --- | --- |
| Homebrew downloads | `brew cleanup --prune=all -s` | Yes |
| JetBrains caches | `~/Library/Caches/JetBrains` | Yes |
| VS Code caches | `~/Library/Application Support/Code/Cache`<br>`~/Library/Application Support/Code/CachedData`<br>`~/Library/Application Support/Code/CachedExtensionVSIXs` | Yes |
| Cursor caches | `~/Library/Application Support/Cursor/Cache`<br>`~/Library/Application Support/Cursor/CachedData` | Yes |
| Playwright browsers | `~/Library/Caches/ms-playwright` | Yes |
| Cypress binaries | `~/Library/Caches/Cypress` | Yes |
| Puppeteer & Chrome DevTools browsers | `~/.cache/puppeteer`<br>`~/.cache/chrome-devtools-mcp` | Yes |
| Terraform plugin cache | `~/.terraform.d/plugin-cache` | Yes |
| Pulumi plugins | `~/.pulumi/plugins` | No |
| Helm cache | `~/Library/Caches/helm` | Yes |
| AWS CLI cache | `~/Library/Caches/aws` | Yes |
| Ollama models | `~/.ollama/models` | No |
| Claude Code scratchpads | `/private/tmp/claude-*` | No |
| Codex caches | `~/Library/Caches/com.openai.codex`<br>`~/.cache/codex-runtimes` | Yes |

## Apps & system

| Cache | Removes | Selected |
| --- | --- | --- |
| App updater leftovers | `~/Library/Caches/*.ShipIt` | Yes |
| Spotify cache | `~/Library/Caches/com.spotify.client` | Yes |
| Slack cache | `~/Library/Application Support/Slack/Cache`<br>`~/Library/Application Support/Slack/Service Worker/CacheStorage` | Yes |
| Chrome / Brave / Edge cache | `~/Library/Caches/Google/Chrome`<br>`~/Library/Caches/BraveSoftware`<br>`~/Library/Caches/Microsoft Edge` | Yes |
| User logs | `~/Library/Logs` | No |
| Trash | `~/.Trash` | No |

## How sizes are measured

| Kind of cache | Source of the size |
| --- | --- |
| Folders | `du`, the space the files occupy on disk |
| Docker build cache, images, containers | The reclaimable size reported by `docker system df` |
| Docker dangling images | `docker images -f dangling=true` |
| Docker anonymous volumes | `docker system df -v`, volumes with a generated name and no container |

## Add a cache

Adding a cache is one line in `Sources/MacOSFlusher/Catalog.swift`. [Build from source](/reference/build#add-a-cache) shows the fields.
