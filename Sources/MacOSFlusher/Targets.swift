import Foundation

enum FlushAction: Sendable {
    case removePaths
    case command(String)
}

enum Audience: String, CaseIterable, Identifiable, Sendable {
    case everyone
    case office
    case ai
    case developers
    case mine

    var id: String { rawValue }
}

enum Risk: Sendable {
    case rebuilds
    case redownload
    case data
}

struct Target: Identifiable, Sendable {
    let id: String
    let name: String
    let detail: String
    let paths: [String]
    let sizeCommand: String?
    let flush: FlushAction
    let requires: String?
    let risk: Risk
    let custom: Bool

    var defaultOn: Bool { risk == .rebuilds }

    init(
        _ id: String,
        _ name: String,
        _ paths: [String] = [],
        detail: String? = nil,
        sizeCommand: String? = nil,
        flush: FlushAction = .removePaths,
        requires: String? = nil,
        risk: Risk = .rebuilds,
        custom: Bool = false
    ) {
        self.id = id
        self.name = name
        self.detail = detail ?? paths.joined(separator: ", ")
        self.paths = paths
        self.sizeCommand = sizeCommand
        self.flush = flush
        self.requires = requires
        self.risk = risk
        self.custom = custom
    }
}

struct TargetGroup: Identifiable, Sendable {
    let id: String
    let name: String
    let audience: Audience
    let items: [Target]
}

private func dockerDF(_ type: String) -> String {
    "docker system df --format '{{.Type}}|{{.Reclaimable}}' 2>/dev/null | awk -F'|' '$1==\"\(type)\"{print $2}'"
}

enum Targets {
    static let groups: [TargetGroup] = [
        TargetGroup(id: "web", name: "Web browsers", audience: .everyone, items: [
            Target("chrome", "Chrome cache", ["~/Library/Caches/Google/Chrome"]),
            Target("brave", "Brave cache", ["~/Library/Caches/BraveSoftware"]),
            Target("edge", "Edge cache", ["~/Library/Caches/Microsoft Edge"]),
        ]),
        TargetGroup(id: "media", name: "Music and video", audience: .everyone, items: [
            Target("spotify", "Spotify cache", ["~/Library/Caches/com.spotify.client"]),
        ]),
        TargetGroup(id: "system", name: "System", audience: .everyone, items: [
            Target("shipit", "App updater leftovers", ["~/Library/Caches/*.ShipIt"]),
            Target("logs", "User logs", ["~/Library/Logs"], risk: .data),
            Target("trash", "Trash", ["~/.Trash"], risk: .data),
        ]),
        TargetGroup(id: "chat", name: "Chat and meetings", audience: .office, items: [
            Target("slack", "Slack cache", ["~/Library/Application Support/Slack/Cache", "~/Library/Application Support/Slack/Service Worker/CacheStorage"]),
        ]),
        TargetGroup(id: "models", name: "Downloaded models", audience: .ai, items: [
            Target("huggingface", "Hugging Face hub", ["~/.cache/huggingface"], risk: .redownload),
            Target("torch", "PyTorch hub", ["~/.cache/torch"], risk: .redownload),
            Target("ollama", "Ollama models", ["~/.ollama/models"], risk: .redownload),
        ]),
        TargetGroup(id: "js", name: "JavaScript / TypeScript", audience: .developers, items: [
            Target("npm", "npm cache", ["~/.npm/_cacache"], flush: .command("npm cache clean --force"), requires: "npm"),
            Target("yarn", "Yarn cache", ["~/Library/Caches/Yarn", "~/.yarn/cache", "~/.yarn/berry/cache"]),
            Target("pnpm", "pnpm store", ["~/Library/pnpm/store", "~/Library/Caches/pnpm", "~/.pnpm-store"]),
            Target("bun", "Bun install cache", ["~/.bun/install/cache"]),
            Target("deno", "Deno cache", ["~/Library/Caches/deno"]),
            Target("corepack", "Corepack cache", ["~/.cache/node/corepack"]),
            Target("nvm", "nvm download cache", ["~/.nvm/.cache"]),
            Target("node-gyp", "node-gyp headers", ["~/Library/Caches/node-gyp", "~/.node-gyp"]),
            Target("electron", "Electron downloads", ["~/Library/Caches/electron", "~/.electron", "~/Library/Caches/electron-builder"]),
            Target("turbo", "Turborepo cache", ["~/Library/Caches/turborepo", "~/.turbo"]),
        ]),
        TargetGroup(id: "python", name: "Python", audience: .developers, items: [
            Target("pip", "pip cache", ["~/Library/Caches/pip"]),
            Target("uv", "uv cache", ["~/.cache/uv"]),
            Target("poetry", "Poetry cache", ["~/Library/Caches/pypoetry"]),
            Target("pipenv", "Pipenv cache", ["~/Library/Caches/pipenv"]),
            Target("pipx", "pipx cache", ["~/.local/pipx/.cache"]),
            Target("conda", "Conda package cache", ["~/miniconda3/pkgs", "~/anaconda3/pkgs", "~/miniforge3/pkgs", "~/.conda/pkgs"]),
            Target("ruff", "Ruff cache", ["~/Library/Caches/ruff", "~/.cache/ruff"]),
            Target("pre-commit", "pre-commit environments", ["~/.cache/pre-commit"]),
        ]),
        TargetGroup(id: "go", name: "Go", audience: .developers, items: [
            Target("go-build", "Go build cache", ["~/Library/Caches/go-build"], flush: .command("go clean -cache"), requires: "go"),
            Target("go-mod", "Go module cache", ["~/go/pkg/mod"], flush: .command("go clean -modcache"), requires: "go", risk: .redownload),
            Target("go-tools", "Go tools (gopls, goimports, golangci-lint, staticcheck)", ["~/Library/Caches/gopls", "~/Library/Caches/goimports", "~/Library/Caches/golangci-lint", "~/Library/Caches/staticcheck"]),
        ]),
        TargetGroup(id: "rust", name: "Rust", audience: .developers, items: [
            Target("cargo", "Cargo registry & git", ["~/.cargo/registry/cache", "~/.cargo/registry/src", "~/.cargo/git"]),
            Target("rustup", "rustup downloads", ["~/.rustup/downloads", "~/.rustup/tmp"]),
            Target("sccache", "sccache", ["~/Library/Caches/Mozilla.sccache", "~/.cache/sccache"]),
        ]),
        TargetGroup(id: "jvm", name: "JVM (Java, Kotlin, Scala, Clojure, Android)", audience: .developers, items: [
            Target("gradle", "Gradle caches", ["~/.gradle/caches", "~/.gradle/daemon"]),
            Target("maven", "Maven repository", ["~/.m2/repository"], risk: .redownload),
            Target("coursier", "Coursier / sbt cache", ["~/Library/Caches/Coursier", "~/.cache/coursier", "~/.sbt/boot", "~/.ivy2/cache"]),
            Target("kotlin", "Kotlin daemon & konan", ["~/.kotlin", "~/.konan/cache"]),
            Target("android", "Android build cache", ["~/.android/cache", "~/.android/build-cache"]),
            Target("bazel", "Bazel cache", ["~/.cache/bazel", "/private/var/tmp/_bazel_*"], risk: .redownload),
        ]),
        TargetGroup(id: "dotnet", name: ".NET", audience: .developers, items: [
            Target("nuget", "NuGet packages", ["~/.nuget/packages"], risk: .redownload),
            Target("nuget-http", "NuGet HTTP cache", ["~/.local/share/NuGet/http-cache", "~/.nuget/v3-cache"]),
        ]),
        TargetGroup(id: "apple", name: "Swift / Objective-C", audience: .developers, items: [
            Target("xcode-derived", "Xcode DerivedData", ["~/Library/Developer/Xcode/DerivedData"]),
            Target("xcode-devicesupport", "Xcode iOS DeviceSupport", ["~/Library/Developer/Xcode/iOS DeviceSupport"], risk: .redownload),
            Target("simulator", "iOS Simulator caches", ["~/Library/Developer/CoreSimulator/Caches"]),
            Target("swiftpm", "Swift PM cache", ["~/Library/Caches/org.swift.swiftpm"]),
            Target("cocoapods", "CocoaPods cache", ["~/Library/Caches/CocoaPods"]),
            Target("carthage", "Carthage cache", ["~/Library/Caches/carthage", "~/Library/Caches/org.carthage.CarthageKit"]),
        ]),
        TargetGroup(id: "ruby-php", name: "Ruby / PHP / Perl / Lua", audience: .developers, items: [
            Target("gems", "RubyGems & Bundler cache", ["~/.gem/specs", "~/.gem/ruby/*/cache", "~/.bundle/cache"]),
            Target("composer", "Composer cache", ["~/.composer/cache", "~/Library/Caches/composer", "~/.cache/composer"]),
            Target("cpan", "CPAN build & sources", ["~/.cpan/build", "~/.cpan/sources", "~/.cpanm/work"]),
            Target("luarocks", "LuaRocks cache", ["~/.cache/luarocks"]),
        ]),
        TargetGroup(id: "beam-fp", name: "Elixir / Erlang / Haskell / OCaml", audience: .developers, items: [
            Target("hex", "Hex package cache", ["~/.hex", "~/.cache/hex"]),
            Target("rebar3", "rebar3 cache", ["~/.cache/rebar3"]),
            Target("cabal", "Cabal packages", ["~/.cabal/packages", "~/.cache/cabal"]),
            Target("stack", "Stack indices", ["~/.stack/indices", "~/.stack/pantry"], risk: .redownload),
            Target("opam", "opam download cache", ["~/.opam/download-cache"]),
        ]),
        TargetGroup(id: "native", name: "C / C++", audience: .developers, items: [
            Target("ccache", "ccache", ["~/Library/Caches/ccache", "~/.ccache", "~/.cache/ccache"]),
            Target("conan", "Conan packages", ["~/.conan2/p", "~/.conan/data"]),
            Target("vcpkg", "vcpkg cache", ["~/.cache/vcpkg", "~/Library/Caches/vcpkg"]),
        ]),
        TargetGroup(id: "other-lang", name: "Dart, Zig, Nim, Julia, R, Crystal, D", audience: .developers, items: [
            Target("pub", "Dart / Flutter pub cache", ["~/.pub-cache"], risk: .redownload),
            Target("zig", "Zig cache", ["~/.cache/zig"]),
            Target("nim", "Nim cache", ["~/.cache/nim", "~/.nimble/pkgcache"]),
            Target("julia", "Julia compiled cache", ["~/.julia/compiled", "~/.julia/logs"]),
            Target("r", "R cache", ["~/Library/Caches/org.R-project.R", "~/.cache/R"]),
            Target("crystal", "Crystal cache", ["~/.cache/crystal"]),
            Target("dub", "D dub packages", ["~/.dub/packages"]),
        ]),
        TargetGroup(id: "containers", name: "Containers & VMs", audience: .developers, items: [
            Target("docker-build", "Docker build cache", detail: "docker builder prune -af",
                      sizeCommand: dockerDF("Build Cache"), flush: .command("docker builder prune -af"), requires: "docker"),
            Target("docker-dangling", "Docker dangling images", detail: "docker image prune -f",
                      sizeCommand: "docker images -f dangling=true --format '{{.Size}}' 2>/dev/null",
                      flush: .command("docker image prune -f"), requires: "docker"),
            Target("docker-images", "Docker unused images (all)", detail: "docker image prune -af",
                      sizeCommand: dockerDF("Images"), flush: .command("docker image prune -af"), requires: "docker", risk: .redownload),
            Target("docker-volumes", "Docker anonymous unused volumes", detail: "docker volume prune -f (named volumes are kept)",
                      sizeCommand: "docker system df -v --format '{{range .Volumes}}{{.Name}}|{{.Links}}|{{.Size}}{{\"\\n\"}}{{end}}' 2>/dev/null | awk -F'|' 'length($1)==64 && $2==0 {print $3}'",
                      flush: .command("docker volume prune -f"), requires: "docker"),
            Target("docker-containers", "Docker stopped containers", detail: "docker container prune -f",
                      sizeCommand: dockerDF("Containers"), flush: .command("docker container prune -f"), requires: "docker", risk: .data),
            Target("podman", "Podman unused data", detail: "podman system prune -af",
                      flush: .command("podman system prune -af"), requires: "podman", risk: .data),
            Target("minikube", "minikube cache", ["~/.minikube/cache"], risk: .redownload),
            Target("vagrant", "Vagrant boxes", ["~/.vagrant.d/boxes"], risk: .redownload),
            Target("lima", "Lima / Colima cache", ["~/Library/Caches/lima"], risk: .redownload),
        ]),
        TargetGroup(id: "tools", name: "IDEs & dev tools", audience: .developers, items: [
            Target("brew", "Homebrew downloads", ["~/Library/Caches/Homebrew"], detail: "brew cleanup --prune=all -s", flush: .command("brew cleanup --prune=all -s"), requires: "brew"),
            Target("jetbrains", "JetBrains caches", ["~/Library/Caches/JetBrains"]),
            Target("vscode", "VS Code caches", ["~/Library/Application Support/Code/Cache", "~/Library/Application Support/Code/CachedData", "~/Library/Application Support/Code/CachedExtensionVSIXs"]),
            Target("cursor", "Cursor caches", ["~/Library/Application Support/Cursor/Cache", "~/Library/Application Support/Cursor/CachedData"]),
            Target("playwright", "Playwright browsers", ["~/Library/Caches/ms-playwright"]),
            Target("cypress", "Cypress binaries", ["~/Library/Caches/Cypress"]),
            Target("puppeteer", "Puppeteer & Chrome DevTools browsers", ["~/.cache/puppeteer", "~/.cache/chrome-devtools-mcp"]),
            Target("terraform", "Terraform plugin cache", ["~/.terraform.d/plugin-cache"]),
            Target("pulumi", "Pulumi plugins", ["~/.pulumi/plugins"], risk: .redownload),
            Target("helm", "Helm cache", ["~/Library/Caches/helm"]),
            Target("aws", "AWS CLI cache", ["~/Library/Caches/aws"]),
            Target("claude-tmp", "Claude Code scratchpads", ["/private/tmp/claude-*"], risk: .data),
            Target("codex", "Codex caches", ["~/Library/Caches/com.openai.codex", "~/.cache/codex-runtimes"]),
        ]),
    ]

    static var allItems: [Target] { groups.flatMap(\.items) }
}
