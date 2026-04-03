import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            List {
                Text("Global Settings")
            }
            .navigationTitle("Claude Control Pane")
        } detail: {
            Text("Select a settings scope")
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 700, minHeight: 500)
    }
}
