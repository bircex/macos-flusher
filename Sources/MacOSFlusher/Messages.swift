import Foundation

enum Messages {
    static let everyone = "Everyone"
    static let office = "Chat, mail and office"
    static let ai = "AI models"
    static let developers = "Developers"

    static let slowToGetBack = "slow to get back"
    static let deletedForGood = "deleted for good"

    static let rebuiltOnDemand = "Caches are rebuilt on demand."
    static let slowToGetBackList = "Slow to get back: "
    static let deletedForGoodList = "Deleted for good: "
    static let neverTouched = "Named Docker volumes and project files are never touched."

    static func targets(_ count: Int) -> String {
        count == 1 ? "1 target" : "\(count) targets"
    }
}

extension Audience {
    var name: String {
        switch self {
        case .everyone: return Messages.everyone
        case .office: return Messages.office
        case .ai: return Messages.ai
        case .developers: return Messages.developers
        }
    }
}

extension Risk {
    var label: String? {
        switch self {
        case .rebuilds: return nil
        case .redownload: return Messages.slowToGetBack
        case .data: return Messages.deletedForGood
        }
    }
}

extension Array where Element == Target {
    var warning: String {
        let slow = filter { $0.risk == .redownload }.map(\.name)
        let gone = filter { $0.risk == .data }.map(\.name)
        var lines: [String] = []
        if contains(where: { $0.risk == .rebuilds }) { lines.append(Messages.rebuiltOnDemand) }
        if !slow.isEmpty { lines.append(Messages.slowToGetBackList + slow.joined(separator: ", ") + ".") }
        if !gone.isEmpty { lines.append(Messages.deletedForGoodList + gone.joined(separator: ", ") + ".") }
        lines.append(Messages.neverTouched)
        return lines.joined(separator: "\n")
    }
}
