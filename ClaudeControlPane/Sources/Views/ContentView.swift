import SwiftUI

struct ContentView: View {
    @State private var store = SettingsStore()
    @State private var selection: SidebarItem? = .global

    var body: some View {
        NavigationSplitView {
            SidebarView(store: store, selection: $selection)
        } detail: {
            if let selection {
                switch selection {
                case .global:
                    SettingsDetailView(
                        manager: store.globalManager,
                        title: "Global Settings"
                    )
                case .project(let path):
                    if let entry = store.projectManagers.first(where: { $0.path == path }) {
                        SettingsDetailView(
                            manager: entry.manager,
                            title: entry.name
                        )
                    }
                case .discovered(let path):
                    if let project = store.discoveredProjects.first(where: { $0.path == path }) {
                        ReadOnlySettingsDetailView(
                            projectPath: project.path,
                            title: project.name
                        )
                    }
                }
            } else {
                Text("Select a settings scope")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 700, minHeight: 500)
    }
}
