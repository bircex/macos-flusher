import Foundation

enum Messages {
    static let everyone = "General"
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

    static let scan = "Scan"
    static let flushSelected = "Flush selected"
    static let stop = "Stop"
    static let hideEmpty = "Hide empty"
    static let flushMenu = "Flush"
    static let home = "Home"
    static let all = "All"
    static let scans = "Scans"
    static let charts = "Charts"
    static let activity = "Activity"
    static let nothingHere = "Nothing to clean here."
    static let noOwnTargets = "No targets of your own yet."
    static let addTarget = "Add target…"
    static let appName = "MacOS Flusher"
    static let general = "General"
    static let about = "About"
    static let appearance = "Appearance"
    static let appearanceSystem = "System"
    static let appearanceLight = "Light"
    static let appearanceDark = "Dark"
    static let version = "Version"
    static let developmentBuild = "Development build"
    static let credit = "Made by BirceX, Recep's AI assistant."
    static let repository = "GitHub repository"
    static let website = "Website"
    static let reportProblem = "Report a problem"
    static let license = "MIT License"
    static let noActivityYet = "No activity yet"

    static let homeTitle = "Get your disk space back"
    static let homeLead = "MacOS Flusher finds the caches and leftovers your apps and tools leave behind, shows what fills the disk and deletes what you choose."
    static let homeStepScan = "Scan"
    static let homeStepScanText = "The app measures every target when it opens. Press Scan (⌘R) to measure again. The line at the top shows the free space now and what it will be after the flush."
    static let homeStepChoose = "Choose"
    static let homeStepChooseText = "Open a page under Scans and tick what you want to delete. Targets that rebuild themselves are ticked from the start. Targets marked slow to get back or deleted for good start unticked."
    static let homeStepFlush = "Flush"
    static let homeStepFlushText = "Press Flush selected (⌘⏎) and confirm. Each target is cleaned and measured again. Every step is listed under Activity."
    static let homeOwn = "Your own targets"
    static let homeOwnText = "Add a folder or a command of your own with File, Add target (⌘N). They appear under My targets and are never ticked from the start."
    static let homeMore = "Charts shows where the space is. Settings (⌘,) holds the appearance and the links to the project."
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
