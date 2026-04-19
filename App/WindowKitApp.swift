import SwiftUI

@main
struct WindowKitApp: App {
    var body: some Scene {
        MenuBarExtra("WindowKit", systemImage: "rectangle.3.group") {
            Text("WindowKit")
            Divider()
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
        .menuBarExtraStyle(.menu)
    }
}
