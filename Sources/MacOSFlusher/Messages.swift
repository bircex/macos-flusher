import Foundation

enum Messages {
    static let everyone = "Everyone"
    static let office = "Chat, mail and office"
    static let ai = "AI models"
    static let developers = "Developers"
    static let mine = "My targets"
    static let addedByYou = "Added by you"

    static let slowToGetBack = "slow to get back"
    static let deletedForGood = "deleted for good"

    static let rebuiltOnDemand = "Caches are rebuilt on demand."
    static let slowToGetBackList = "Slow to get back: "
    static let deletedForGoodList = "Deleted for good: "
    static let neverTouched = "Named Docker volumes and project files are never touched."

    static let addTarget = "Add target…"
    static let edit = "Edit"
    static let editorName = "Name"
    static let editorFolders = "Folders"
    static let editorFoldersHint = "One folder per line. Everything inside is deleted, the folder itself stays."
    static let editorCommand = "Command"
    static let editorCommandHint = "Optional. Runs in zsh exactly as written. With a command, the folders are only measured."
    static let chooseFolder = "Choose folder…"
    static let responsibility = "MacOS Flusher deletes everything inside these folders and runs the command exactly as written. Nothing goes to the Trash and nothing can be restored. You are responsible for what this target removes."
    static let understood = "I understand and take responsibility"

    static let nameMissing = "Give the target a name."
    static let nothingToClean = "Add a folder or a command."
    static let notAPath = "Start the folder with ~/ or /."
    static let noWildcards = "Folders cannot contain * or ?."
    static let noParent = "Folders cannot contain \"..\"."
    static let outsideHome = "The folder must be inside your home folder."
    static let tooShallow = "The folder is too close to the top of your home folder. Choose one at least two levels deep, inside Library three."
    static let ownData = "This folder holds the data of MacOS Flusher."
    static let storageBroken = "My targets could not be read. The file was kept as "
    static let storageFailed = "My targets could not be saved: "

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
        case .mine: return Messages.mine
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
