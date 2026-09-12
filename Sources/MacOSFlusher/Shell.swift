import Foundation
import Darwin

enum Shell {
    static let home = FileManager.default.homeDirectoryForCurrentUser.path

    static let path: String = {
        let fixed = ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin", "/usr/sbin", "/sbin", home + "/go/bin", home + "/.cargo/bin"]
        let login = runSync("/bin/zsh", ["-lc", "print -r -- $PATH"], path: nil).output
            .trimmingCharacters(in: .whitespacesAndNewlines)
        var seen = Set<String>()
        return (fixed + login.split(separator: ":").map(String.init))
            .filter { !$0.isEmpty && seen.insert($0).inserted }
            .joined(separator: ":")
    }()

    static func run(_ executable: String, _ arguments: [String]) async -> (status: Int32, output: String) {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(returning: runSync(executable, arguments, path: path))
            }
        }
    }

    static func command(_ command: String) async -> (status: Int32, output: String) {
        await run("/bin/zsh", ["-c", command])
    }

    static func warmUp() {
        DispatchQueue.global(qos: .utility).async { _ = path }
    }

    private static func runSync(_ executable: String, _ arguments: [String], path: String?) -> (status: Int32, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        var env = ProcessInfo.processInfo.environment
        if let path { env["PATH"] = path }
        process.environment = env
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        process.standardInput = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            return (127, error.localizedDescription)
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, String(decoding: data, as: UTF8.self))
    }

    static func exists(binary: String) -> Bool {
        path.split(separator: ":").contains { dir in
            FileManager.default.isExecutableFile(atPath: "\(dir)/\(binary)")
        }
    }

    static func expand(_ pattern: String) -> [String] {
        var expanded = pattern
        if expanded.hasPrefix("~/") {
            expanded = home + expanded.dropFirst(1)
        }
        guard expanded.contains("*") else {
            return FileManager.default.fileExists(atPath: expanded) ? [expanded] : []
        }
        var result = glob_t()
        defer { globfree(&result) }
        guard glob(expanded, 0, nil, &result) == 0 else { return [] }
        return (0..<Int(result.gl_pathc)).compactMap { index in
            result.gl_pathv[index].map { String(cString: $0) }
        }
    }

    static func sizeOfPaths(_ patterns: [String]) async -> Int64 {
        let paths = patterns.flatMap(expand)
        guard !paths.isEmpty else { return 0 }
        let out = await run("/usr/bin/du", ["-skc"] + paths).output
        guard let last = out.split(separator: "\n").last,
              let kb = Int64(last.split(separator: "\t").first ?? "") else { return 0 }
        return kb * 1024
    }

    static func removePaths(_ patterns: [String]) async -> (status: Int32, output: String) {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                var failures: [String] = []
                let fm = FileManager.default
                for pattern in patterns {
                    let isGlob = pattern.contains("*")
                    for path in expand(pattern) {
                        var isDir: ObjCBool = false
                        fm.fileExists(atPath: path, isDirectory: &isDir)
                        let targets = (isDir.boolValue && !isGlob)
                            ? ((try? fm.contentsOfDirectory(atPath: path)) ?? []).map { path + "/" + $0 }
                            : [path]
                        for target in targets {
                            do {
                                try fm.removeItem(atPath: target)
                            } catch {
                                failures.append(target + ": " + error.localizedDescription)
                            }
                        }
                    }
                }
                continuation.resume(returning: (failures.isEmpty ? 0 : 1, failures.joined(separator: "\n")))
            }
        }
    }

    static func parseSizes(_ text: String) -> Int64 {
        text.split(separator: "\n").reduce(0) { $0 + parseSize(String($1)) }
    }

    static func parseSize(_ raw: String) -> Int64 {
        let scanner = Scanner(string: raw.trimmingCharacters(in: .whitespaces))
        guard let number = scanner.scanDouble() else { return 0 }
        let unit = scanner.scanCharacters(from: .letters)?.lowercased() ?? "b"
        let multipliers: [String: Double] = [
            "b": 1, "k": 1e3, "kb": 1e3, "kib": 1024,
            "m": 1e6, "mb": 1e6, "mib": 1_048_576,
            "g": 1e9, "gb": 1e9, "gib": 1_073_741_824,
            "t": 1e12, "tb": 1e12, "tib": 1_099_511_627_776,
        ]
        return Int64(number * (multipliers[unit] ?? 1))
    }
}
