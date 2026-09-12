import SwiftUI

@main
struct MacOSFlusherApp: App {
    @StateObject private var store = Store()

    var body: some Scene {
        WindowGroup("MacOS Flusher") {
            ContentView().environmentObject(store)
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
