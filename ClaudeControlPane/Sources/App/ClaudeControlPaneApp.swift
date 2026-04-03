import SwiftUI

@main
struct ClaudeControlPaneApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 800, height: 600)
    }
}
