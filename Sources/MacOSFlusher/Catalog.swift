import Foundation

enum FlushAction: Sendable {
    case removePaths
    case command(String)
}

struct CacheItem: Identifiable, Sendable {
    let id: String
    let name: String
    let detail: String
    let paths: [String]
    let sizeCommand: String?
    let flush: FlushAction
    let requires: String?
    let defaultOn: Bool

    init(
        _ id: String,
        _ name: String,
        _ paths: [String] = [],
        detail: String? = nil,
        sizeCommand: String? = nil,
        flush: FlushAction = .removePaths,
        requires: String? = nil,
        defaultOn: Bool = true
    ) {
        self.id = id
        self.name = name
        self.detail = detail ?? paths.joined(separator: ", ")
        self.paths = paths
        self.sizeCommand = sizeCommand
        self.flush = flush
        self.requires = requires
        self.defaultOn = defaultOn
    }
}

struct CacheGroup: Identifiable, Sendable {
    let id: String
    let name: String
    let items: [CacheItem]
}

private func dockerDF(_ type: String) -> String {
    "docker system df --format '{{.Type}}|{{.Reclaimable}}' 2>/dev/null | awk -F'|' '$1==\"\(type)\"{print $2}'"
}

enum Catalog {
    static let groups: [CacheGroup] = [
        CacheGroup(id: "js", name: "JavaScript / TypeScript", items: [
            CacheItem("npm", "npm cache", ["~/.npm/_cacache"], flush: .command("npm cache clean --force"), requires: "npm"),
            CacheItem("yarn", "Yarn cache", ["~/Library/Caches/Yarn", "~/.yarn/cache", "~/.yarn/berry/cache"]),
            CacheItem("pnpm", "pnpm store", ["~/Library/pnpm/store", "~/Library/Caches/pnpm", "~/.pnpm-store"]),
            CacheItem("bun", "Bun install cache", ["~/.bun/install/cache"]),
            CacheItem("deno", "Deno cache", ["~/Library/Caches/deno"]),
            CacheItem("corepack", "Corepack cache", ["~/.cache/node/corepack"]),
            CacheItem("nvm", "nvm download cache", ["~/.nvm/.cache"]),
            CacheItem("node-gyp", "node-gyp headers", ["~/Library/Caches/node-gyp", "~/.node-gyp"]),
            CacheItem("electron", "Electron downloads", ["~/Library/Caches/electron", "~/.electron", "~/Library/Caches/electron-builder"]),
            CacheItem("turbo", "Turborepo cache", ["~/Library/Caches/turborepo", "~/.turbo"]),
        ]),
        CacheGroup(id: "python", name: "Python", items: [
            CacheItem("pip", "pip cache", ["~/Library/Caches/pip"]),
            CacheItem("uv", "uv cache", ["~/.cache/uv"]),
            CacheItem("poetry", "Poetry cache", ["~/Library/Caches/pypoetry"]),
            CacheItem("pipenv", "Pipenv cache", ["~/Library/Caches/pipenv"]),
            CacheItem("pipx", "pipx cache", ["~/.local/pipx/.cache"]),
            CacheItem("conda", "Conda package cache", ["~/miniconda3/pkgs", "~/anaconda3/pkgs", "~/miniforge3/pkgs", "~/.conda/pkgs"]),
            CacheItem("ruff", "Ruff cache", ["~/Library/Caches/ruff", "~/.cache/ruff"]),
            CacheItem("pre-commit", "pre-commit environments", ["~/.cache/pre-commit"]),
            CacheItem("huggingface", "Hugging Face hub", ["~/.cache/huggingface"], defaultOn: false),
            CacheItem("torch", "PyTorch hub", ["~/.cache/torch"], defaultOn: false),
        ]),
        CacheGroup(id: "go", name: "Go", items: [
            CacheItem("go-build", "Go build cache", ["~/Library/Caches/go-build"], flush: .command("go clean -cache"), requires: "go"),
            CacheItem("go-mod", "Go module cache", ["~/go/pkg/mod"], detail: "~/go/pkg/mod (slow to re-download)", flush: .command("go clean -modcache"), requires: "go", defaultOn: false),
            CacheItem("go-tools", "Go tools (gopls, goimports, golangci-lint, staticcheck)", ["~/Library/Caches/gopls", "~/Library/Caches/goimports", "~/Library/Caches/golangci-lint", "~/Library/Caches/staticcheck"]),
        ]),
        CacheGroup(id: "rust", name: "Rust", items: [
            CacheItem("cargo", "Cargo registry & git", ["~/.cargo/registry/cache", "~/.cargo/registry/src", "~/.cargo/git"]),
            CacheItem("rustup", "rustup downloads", ["~/.rustup/downloads", "~/.rustup/tmp"]),
            CacheItem("sccache", "sccache", ["~/Library/Caches/Mozilla.sccache", "~/.cache/sccache"]),
        ]),
        CacheGroup(id: "jvm", name: "JVM (Java, Kotlin, Scala, Clojure, Android)", items: [
            CacheItem("gradle", "Gradle caches", ["~/.gradle/caches", "~/.gradle/daemon"]),
            CacheItem("maven", "Maven repository", ["~/.m2/repository"], detail: "~/.m2/repository (slow to re-download)", defaultOn: false),
            CacheItem("coursier", "Coursier / sbt cache", ["~/Library/Caches/Coursier", "~/.cache/coursier", "~/.sbt/boot", "~/.ivy2/cache"]),
            CacheItem("kotlin", "Kotlin daemon & konan", ["~/.kotlin", "~/.konan/cache"]),
            CacheItem("android", "Android build cache", ["~/.android/cache", "~/.android/build-cache"]),
            CacheItem("bazel", "Bazel cache", ["~/.cache/bazel", "/private/var/tmp/_bazel_*"], defaultOn: false),
        ]),
        CacheGroup(id: "dotnet", name: ".NET", items: [
            CacheItem("nuget", "NuGet packages", ["~/.nuget/packages"], detail: "~/.nuget/packages (slow to re-download)", defaultOn: false),
            CacheItem("nuget-http", "NuGet HTTP cache", ["~/.local/share/NuGet/http-cache", "~/.nuget/v3-cache"]),
        ]),
        CacheGroup(id: "apple", name: "Swift / Objective-C", items: [
            CacheItem("xcode-derived", "Xcode DerivedData", ["~/Library/Developer/Xcode/DerivedData"]),
            CacheItem("xcode-devicesupport", "Xcode iOS DeviceSupport", ["~/Library/Developer/Xcode/iOS DeviceSupport"], defaultOn: false),
            CacheItem("simulator", "iOS Simulator caches", ["~/Library/Developer/CoreSimulator/Caches"]),
            CacheItem("swiftpm", "Swift PM cache", ["~/Library/Caches/org.swift.swiftpm"]),
            CacheItem("cocoapods", "CocoaPods cache", ["~/Library/Caches/CocoaPods"]),
            CacheItem("carthage", "Carthage cache", ["~/Library/Caches/carthage", "~/Library/Caches/org.carthage.CarthageKit"]),
        ]),
        CacheGroup(id: "ruby-php", name: "Ruby / PHP / Perl / Lua", items: [
            CacheItem("gems", "RubyGems & Bundler cache", ["~/.gem/specs", "~/.gem/ruby/*/cache", "~/.bundle/cache"]),
            CacheItem("composer", "Composer cache", ["~/.composer/cache", "~/Library/Caches/composer", "~/.cache/composer"]),
            CacheItem("cpan", "CPAN build & sources", ["~/.cpan/build", "~/.cpan/sources", "~/.cpanm/work"]),
            CacheItem("luarocks", "LuaRocks cache", ["~/.cache/luarocks"]),
        ]),
        CacheGroup(id: "beam-fp", name: "Elixir / Erlang / Haskell / OCaml", items: [
            CacheItem("hex", "Hex package cache", ["~/.hex", "~/.cache/hex"]),
            CacheItem("rebar3", "rebar3 cache", ["~/.cache/rebar3"]),
            CacheItem("cabal", "Cabal packages", ["~/.cabal/packages", "~/.cache/cabal"]),
            CacheItem("stack", "Stack indices", ["~/.stack/indices", "~/.stack/pantry"], defaultOn: false),
            CacheItem("opam", "opam download cache", ["~/.opam/download-cache"]),
        ]),
        CacheGroup(id: "native", name: "C / C++", items: [
            CacheItem("ccache", "ccache", ["~/Library/Caches/ccache", "~/.ccache", "~/.cache/ccache"]),
            CacheItem("conan", "Conan packages", ["~/.conan2/p", "~/.conan/data"]),
            CacheItem("vcpkg", "vcpkg cache", ["~/.cache/vcpkg", "~/Library/Caches/vcpkg"]),
        ]),
        CacheGroup(id: "other-lang", name: "Dart, Zig, Nim, Julia, R, Crystal, D", items: [
            CacheItem("pub", "Dart / Flutter pub cache", ["~/.pub-cache"], detail: "~/.pub-cache (slow to re-download)", defaultOn: false),
            CacheItem("zig", "Zig cache", ["~/.cache/zig"]),
            CacheItem("nim", "Nim cache", ["~/.cache/nim", "~/.nimble/pkgcache"]),
            CacheItem("julia", "Julia compiled cache", ["~/.julia/compiled", "~/.julia/logs"]),
            CacheItem("r", "R cache", ["~/Library/Caches/org.R-project.R", "~/.cache/R"]),
            CacheItem("crystal", "Crystal cache", ["~/.cache/crystal"]),
            CacheItem("dub", "D dub packages", ["~/.dub/packages"]),
        ]),
        CacheGroup(id: "containers", name: "Containers & VMs", items: [
            CacheItem("docker-build", "Docker build cache", detail: "docker builder prune -af",
                      sizeCommand: dockerDF("Build Cache"), flush: .command("docker builder prune -af"), requires: "docker"),
            CacheItem("docker-dangling", "Docker dangling images", detail: "docker image prune -f",
                      sizeCommand: "docker images -f dangling=true --format '{{.Size}}' 2>/dev/null",
                      flush: .command("docker image prune -f"), requires: "docker"),
            CacheItem("docker-images", "Docker unused images (all)", detail: "docker image prune -af",
                      sizeCommand: dockerDF("Images"), flush: .command("docker image prune -af"), requires: "docker", defaultOn: false),
            CacheItem("docker-volumes", "Docker anonymous unused volumes", detail: "docker volume prune -f (named volumes are kept)",
                      sizeCommand: "docker system df -v --format '{{range .Volumes}}{{.Name}}|{{.Links}}|{{.Size}}{{\"\\n\"}}{{end}}' 2>/dev/null | awk -F'|' 'length($1)==64 && $2==0 {print $3}'",
                      flush: .command("docker volume prune -f"), requires: "docker"),
            CacheItem("docker-containers", "Docker stopped containers", detail: "docker container prune -f",
                      sizeCommand: dockerDF("Containers"), flush: .command("docker container prune -f"), requires: "docker", defaultOn: false),
            CacheItem("podman", "Podman unused data", detail: "podman system prune -af",
                      flush: .command("podman system prune -af"), requires: "podman", defaultOn: false),
            CacheItem("minikube", "minikube cache", ["~/.minikube/cache"], defaultOn: false),
            CacheItem("vagrant", "Vagrant boxes", ["~/.vagrant.d/boxes"], defaultOn: false),
            CacheItem("lima", "Lima / Colima cache", ["~/Library/Caches/lima"], defaultOn: false),
        ]),
        CacheGroup(id: "tools", name: "IDEs & dev tools", items: [
            CacheItem("brew", "Homebrew downloads", ["~/Library/Caches/Homebrew"], detail: "brew cleanup --prune=all -s", flush: .command("brew cleanup --prune=all -s"), requires: "brew"),
            CacheItem("jetbrains", "JetBrains caches", ["~/Library/Caches/JetBrains"]),
            CacheItem("vscode", "VS Code caches", ["~/Library/Application Support/Code/Cache", "~/Library/Application Support/Code/CachedData", "~/Library/Application Support/Code/CachedExtensionVSIXs"]),
            CacheItem("cursor", "Cursor caches", ["~/Library/Application Support/Cursor/Cache", "~/Library/Application Support/Cursor/CachedData"]),
            CacheItem("playwright", "Playwright browsers", ["~/Library/Caches/ms-playwright"]),
            CacheItem("cypress", "Cypress binaries", ["~/Library/Caches/Cypress"]),
            CacheItem("puppeteer", "Puppeteer & Chrome DevTools browsers", ["~/.cache/puppeteer", "~/.cache/chrome-devtools-mcp"]),
            CacheItem("terraform", "Terraform plugin cache", ["~/.terraform.d/plugin-cache"]),
            CacheItem("pulumi", "Pulumi plugins", ["~/.pulumi/plugins"], defaultOn: false),
            CacheItem("helm", "Helm cache", ["~/Library/Caches/helm"]),
            CacheItem("aws", "AWS CLI cache", ["~/Library/Caches/aws"]),
            CacheItem("ollama", "Ollama models", ["~/.ollama/models"], defaultOn: false),
            CacheItem("claude-tmp", "Claude Code scratchpads", ["/private/tmp/claude-*"], defaultOn: false),
            CacheItem("codex", "Codex caches", ["~/Library/Caches/com.openai.codex", "~/.cache/codex-runtimes"]),
        ]),
        CacheGroup(id: "apps", name: "Apps & system", items: [
            CacheItem("shipit", "App updater leftovers", ["~/Library/Caches/*.ShipIt"]),
            CacheItem("spotify", "Spotify cache", ["~/Library/Caches/com.spotify.client"]),
            CacheItem("slack", "Slack cache", ["~/Library/Application Support/Slack/Cache", "~/Library/Application Support/Slack/Service Worker/CacheStorage"]),
            CacheItem("browsers", "Chrome / Brave / Edge cache", ["~/Library/Caches/Google/Chrome", "~/Library/Caches/BraveSoftware", "~/Library/Caches/Microsoft Edge"]),
            CacheItem("logs", "User logs", ["~/Library/Logs"], defaultOn: false),
            CacheItem("trash", "Trash", ["~/.Trash"], defaultOn: false),
        ]),
    ]

    static var allItems: [CacheItem] { groups.flatMap(\.items) }
}
