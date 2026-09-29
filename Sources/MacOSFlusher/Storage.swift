import Foundation

enum Loaded<Value> {
    case missing
    case value(Value)
    case broken(String)
}

enum Storage {
    static let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("MacOS Flusher")

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    static func load<Value: Decodable>(_ name: String, from folder: URL) -> Loaded<Value> {
        let file = folder.appendingPathComponent(name + ".json")
        guard let data = try? Data(contentsOf: file) else { return .missing }
        if let value = try? decoder.decode(Value.self, from: data) { return .value(value) }
        let kept = spare(name, in: folder)
        try? FileManager.default.moveItem(at: file, to: folder.appendingPathComponent(kept))
        return .broken(kept)
    }

    static func save<Value: Encodable>(_ value: Value, as name: String, in folder: URL) throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try encoder.encode(value).write(to: folder.appendingPathComponent(name + ".json"), options: .atomic)
    }

    private static func spare(_ name: String, in folder: URL) -> String {
        let names = [name + ".broken.json"] + (2...99).map { "\(name).broken.\($0).json" }
        return names.first { !FileManager.default.fileExists(atPath: folder.appendingPathComponent($0).path) } ?? names[0]
    }
}
