import SwiftUI

enum SidebarItem: Hashable {
    case machineSettings
    case machinePreferences
    case machineAgents
    case machineSkills
    case machineInstructions
    case plugins
    case diagnostics
    case sharedSettings(String)
    case localSettings(String)
    case sharedMcp(String)
    case localMcp(String)
    case agents(String)
    case skills(String)
    case instructions(String)
    case discovered(String)
}

struct SidebarView: View {
    @Bindable var store: SettingsStore
    @Binding var selection: SidebarItem?
    @State private var expandedProjects: Set<String> = []

    var body: some View {
        List(selection: $selection) {
            Section("Machine") {
                sidebarRow("Machine Settings", systemImage: "gearshape", item: .machineSettings)
                sidebarRow("Global Preferences", systemImage: "switch.2", item: .machinePreferences)
                sidebarRow("Agents", systemImage: "person.3", item: .machineAgents)
                sidebarRow("Skills", systemImage: "sparkles.rectangle.stack", item: .machineSkills)
                sidebarRow("Instructions", systemImage: "text.page", item: .machineInstructions)
                sidebarRow("Plugins", systemImage: "puzzlepiece.extension", item: .plugins)
                sidebarRow("Diagnostics", systemImage: "stethoscope", item: .diagnostics)
            }

            Section("Projects") {
                ForEach(store.projectManagers) { entry in
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedProjects.contains(entry.path) },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedProjects.insert(entry.path)
                                } else {
                                    expandedProjects.remove(entry.path)
                                }
                            }
                        )
                    ) {
                        sidebarRow("Workspace Shared", systemImage: "folder", item: .sharedSettings(entry.path))
                        sidebarRow("Workspace Local", systemImage: "person.crop.circle", item: .localSettings(entry.path))
                        sidebarRow("Shared MCP", systemImage: "server.rack", item: .sharedMcp(entry.path))
                        sidebarRow("Local MCP", systemImage: "server.rack", item: .localMcp(entry.path))
                        sidebarRow("Agents", systemImage: "person.3", item: .agents(entry.path))
                        sidebarRow("Skills", systemImage: "sparkles.rectangle.stack", item: .skills(entry.path))
                        sidebarRow("Instructions", systemImage: "text.page", item: .instructions(entry.path))
                    } label: {
                        Label(entry.name, systemImage: "folder")
                    }
                    .contextMenu {
                        Button("Remove from List", role: .destructive) {
                            if case .sharedSettings(let path) = selection, path == entry.path {
                                selection = .machineSettings
                            }
                            store.removeProject(entry)
                            expandedProjects.remove(entry.path)
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
                                selection = .sharedSettings(project.path)
                                expandedProjects.insert(project.path)
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
            HStack {
                Button {
                    store.addProject()
                } label: {
                    Label("Add Project...", systemImage: "plus")
                }
                .buttonStyle(.borderless)

                Spacer()

                Button {
                    store.refreshDiscovery()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Refresh discovered projects")
            }
            .padding()
        }
        .navigationTitle("Claude Control Pane")
        .listStyle(.sidebar)
    }

    @ViewBuilder
    private func sidebarRow(_ title: String, systemImage: String, item: SidebarItem) -> some View {
        Label(title, systemImage: systemImage)
            .tag(item)
    }
}
