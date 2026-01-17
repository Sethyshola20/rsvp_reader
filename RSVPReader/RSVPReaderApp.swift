import SwiftUI

@main
struct RSVPReaderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 800, height: 500)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
