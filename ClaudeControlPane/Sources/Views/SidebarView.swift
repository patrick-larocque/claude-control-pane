import SwiftUI

enum SidebarItem: Hashable {
    case global
    case project(String)
    case discovered(String)
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

            if !store.discoveredProjects.isEmpty {
                Section("Discovered") {
                    ForEach(store.discoveredProjects) { project in
                        HStack {
                            Label(project.name, systemImage: "folder.badge.questionmark")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button {
                                store.promoteDiscoveredProject(project)
                                selection = .project(project.path)
                            } label: {
                                Image(systemName: "plus.circle")
                            }
                            .buttonStyle(.borderless)
                            .help("Add to managed projects")
                        }
                        .tag(SidebarItem.discovered(project.path))
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
