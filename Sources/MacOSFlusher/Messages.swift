import Foundation

enum Messages {
    static var browsers: String { localized("Browsers") }
    static var communication: String { localized("Communication") }
    static var office: String { localized("Office and documents") }
    static var media: String { localized("Media") }
    static var design: String { localized("Design and photo") }
    static var games: String { localized("Games") }
    static var ai: String { localized("AI") }
    static var system: String { localized("System") }
    static var developers: String { localized("Developers") }
    static var mine: String { localized("My targets") }
    static var addedByYou: String { localized("Added by you") }

    static var slowToGetBack: String { localized("slow to get back") }
    static var deletedForGood: String { localized("deleted for good") }

    static var rebuiltOnDemand: String { localized("Caches are rebuilt on demand.") }
    static var slowToGetBackList: String { localized("Slow to get back: ") }
    static var deletedForGoodList: String { localized("Deleted for good: ") }
    static var neverTouched: String { localized("Named Docker volumes and project files are never touched.") }

    static var scan: String { localized("Scan") }
    static var flushSelected: String { localized("Flush selected") }
    static var stop: String { localized("Stop") }
    static var hideEmpty: String { localized("Hide empty") }
    static var flushMenu: String { localized("Flush") }
    static var home: String { localized("Home") }
    static var all: String { localized("All") }
    static var scans: String { localized("Scans") }
    static var reports: String { localized("Reports") }
    static var overview: String { localized("Overview") }
    static var locations: String { localized("Locations") }
    static var categories: String { localized("Categories") }
    static var logs: String { localized("Logs") }
    static var nothingHere: String { localized("Nothing to clean here.") }
    static var noOwnTargets: String { localized("No targets of your own yet.") }
    static var addTarget: String { localized("Add target…") }
    static var appName: String { localized("MacOS Flusher") }
    static var settings: String { localized("Settings") }
    static var general: String { localized("General") }
    static var about: String { localized("About") }
    static var appearance: String { localized("Appearance") }
    static var appearanceSystem: String { localized("System") }
    static var appearanceLight: String { localized("Light") }
    static var appearanceDark: String { localized("Dark") }
    static var theme: String { localized("Theme") }
    static var data: String { localized("Data") }
    static var showInFinder: String { localized("Show in Finder") }
    static var version: String { localized("Version") }
    static var developmentBuild: String { localized("Development build") }
    static var credit: String { localized("Made by BirceX, Recep's AI assistant.") }
    static var repository: String { localized("GitHub repository") }
    static var website: String { localized("Website") }
    static var reportProblem: String { localized("Report a problem") }
    static var license: String { localized("MIT License") }
    static var noActivityYet: String { localized("No activity yet") }

    static var homeTitle: String { localized("Get your disk space back") }
    static var homeLead: String { localized("MacOS Flusher finds the caches and leftovers your apps and tools leave behind, shows what fills the disk and deletes what you choose.") }
    static var homeStepScanText: String { localized("The app measures every target when it opens. Press Scan (⌘R) to measure again. The line at the top shows the free space now and what it will be after the flush.") }
    static var homeStepChooseText: String { localized("Open Scan and tick what you want to delete. Sort any column or filter by category. Targets that rebuild themselves are ticked from the start. Targets marked slow to get back or deleted for good start unticked.") }
    static var homeStepFlushText: String { localized("Tick a target and a Flush bar appears above the list. Press it (⌘⏎) and confirm. Each target is cleaned and measured again. Every step is listed under Logs.") }
    static var homeOwn: String { localized("Your own targets") }
    static var homeOwnText: String { localized("Add a folder or a command of your own with File, Add target (⌘N). They appear under My targets and are never ticked from the start.") }
    static var homeMore: String { localized("Reports shows where the space is. Logs lists every step. Settings (⌘,) holds the appearance and the links to the project.") }
    static var edit: String { localized("Edit") }
    static var editorName: String { localized("Name") }
    static var editorFolders: String { localized("Folders") }
    static var editorFoldersHint: String { localized("One folder per line, with the names Terminal shows, not the translated names of the Finder. Everything inside is deleted, the folder itself stays.") }
    static var editorCommand: String { localized("Command") }
    static var editorCommandHint: String { localized("Optional. Runs in zsh exactly as written. With a command, the folders are only measured.") }
    static var chooseFolder: String { localized("Choose folder…") }
    static var responsibility: String { localized("MacOS Flusher deletes everything inside these folders and runs the command exactly as written. Nothing goes to the Trash and nothing can be restored. You are responsible for what this target removes.") }
    static var understood: String { localized("I understand and take responsibility") }

    static var nameMissing: String { localized("Give the target a name.") }
    static var nothingToClean: String { localized("Add a folder or a command.") }
    static var notAPath: String { localized("Start the folder with ~/ or /.") }
    static var noWildcards: String { localized("Folders cannot contain * or ?.") }
    static var noParent: String { localized("Folders cannot contain \"..\".") }
    static var outsideHome: String { localized("The folder must be inside your home folder.") }
    static var tooShallow: String { localized("The folder is too close to the top of your home folder. Choose one at least two levels deep, inside Library three.") }
    static var ownData: String { localized("This folder holds the data of MacOS Flusher.") }
    static let storageBroken = "My targets could not be read. The file was kept as %@."
    static let storageFailed = "My targets could not be saved: %@"
    static let namedProblem = "%@: %@"
    static let scanningKey = "Scanning…"
    static let scanStoppedKey = "Scan stopped."
    static let scanFinishedKey = "Scan finished."
    static let analysisFinishedKey = "Disk analysis finished."

    static var language: String { localized("Language") }
    static var cancel: String { localized("Cancel") }
    static var delete: String { localized("Delete") }
    static var save: String { localized("Save") }
    static var all_: String { localized("All") }
    static var none: String { localized("None") }
    static var notInstalled: String { localized("not installed") }
    static var empty: String { localized("empty") }
    static var activityLog: String { localized("Activity log") }
    static var used: String { localized("used") }
    static var freeOf: String { localized("%@ free of %@") }
    static var selectedIn: String { localized("%@ selected in %@, %@ free after flush") }
    static var freed: String { localized("Freed %@") }
    static let freedLine = "Freed %@."
    static var progressOf: String { localized("%d of %d") }
    static var deleteAcross: String { localized("Delete %@ across %@?") }
    static var otherData: String { localized("Other data") }
    static var unselected: String { localized("Unselected") }
    static var selected: String { localized("Selected") }
    static var unselectedTargets: String { localized("Unselected targets") }
    static var selectedTargets: String { localized("Selected targets") }
    static var free: String { localized("Free") }
    static var ofDisk: String { localized("%@ of disk") }
    static var analyzingOf: String { localized("Analyzing %d of %d") }
    static var usedAmount: String { localized("%@ used") }
    static var byLocation: String { localized("Disk usage by location") }
    static var analyzingDisk: String { localized("Analyzing disk…") }
    static var notAnalyzed: String { localized("Not analyzed yet") }
    static var byGroup: String { localized("Targets by group") }
    static var byCategory: String { localized("By category") }
    static var largestTargets: String { localized("Largest targets") }
    static var exportCSV: String { localized("Export CSV") }
    static var found: String { localized("%@ found") }
    static var scanning: String { localized("Scanning…") }
    static var noTargetsFound: String { localized("No targets found") }
    static var scanStopped: String { localized("Scan stopped.") }
    static var scanFinished: String { localized("Scan finished.") }
    static var analysisFinished: String { localized("Disk analysis finished.") }
    static let flushed = "Flushed %@"
    static var info: String { localized("INFO") }
    static var error: String { localized("ERROR") }
    static var choose: String { localized("Choose") }
    static var findings: String { localized("Findings") }
    static var category: String { localized("Category") }
    static var group: String { localized("Group") }
    static var size: String { localized("Size") }
    static var scanned: String { localized("Scanned") }

    static func targets(_ count: Int) -> String {
        count == 1 ? localized("1 target") : String(format: localized("%d targets"), count)
    }
}

extension Audience {
    var name: String {
        switch self {
        case .browsers: return Messages.browsers
        case .communication: return Messages.communication
        case .office: return Messages.office
        case .media: return Messages.media
        case .design: return Messages.design
        case .games: return Messages.games
        case .ai: return Messages.ai
        case .system: return Messages.system
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
