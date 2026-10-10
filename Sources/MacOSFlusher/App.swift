import SwiftUI

@main
struct MacOSFlusherApp: App {
    @StateObject private var store = Store()

    var body: some Scene {
        WindowGroup(Messages.appName) {
            ContentView().environmentObject(store)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(Messages.addTarget) { store.edited = UserTarget() }
                    .keyboardShortcut("n")
            }
            CommandGroup(after: .toolbar) {
                Toggle(Messages.hideEmpty, isOn: $store.hideEmpty)
                Divider()
                Button(Messages.home) { store.page = .home }
                    .keyboardShortcut("1")
                Button(Messages.overview) { store.page = .overview }
                    .keyboardShortcut("2")
                Button(Messages.activity) { store.page = .activity }
                    .keyboardShortcut("3")
            }
            CommandMenu(Messages.flushMenu) {
                Button(Messages.scan) { store.scan() }
                    .keyboardShortcut("r")
                    .disabled(store.busy)
                Button(Messages.flushSelected) { store.confirmFlush = true }
                    .keyboardShortcut(.return)
                    .disabled(store.busy || store.selectedCount == 0)
                Button(Messages.stop) { store.stop() }
                    .keyboardShortcut(".")
                    .disabled(!store.busy)
            }
        }
        Settings {
            SettingsView().environmentObject(store).id(store.language)
        }
    }
}
