import SwiftUI

enum SidebarItem: Hashable {
    case global
    case project(String)
}

struct SidebarView: View {
    @Bindable var store: SettingsStore
    @Binding var selection: SidebarItem?

    var body: some View {
        List(selection: $selection) {
            Section {
                Label("Global Settings", systemImage: "gearshape")
                    .tag(SidebarItem.global)
            }

            Section("Projects") {
                ForEach(store.projectManagers) { entry in
                    Label(entry.name, systemImage: "folder")
                        .tag(SidebarItem.project(entry.path))
                        .contextMenu {
                            Button("Remove from List", role: .destructive) {
                                if case .project(let path) = selection, path == entry.path {
                                    selection = .global
                                }
                                store.removeProject(entry)
                            }
                        }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                store.addProject()
            } label: {
                Label("Add Project...", systemImage: "plus")
            }
            .buttonStyle(.borderless)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Claude Control Pane")
        .listStyle(.sidebar)
    }
}
