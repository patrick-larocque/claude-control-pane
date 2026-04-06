import SwiftUI

struct ReadOnlySettingsDetailView: View {
    let projectPath: String
    let title: String

    @State private var settings: ClaudeSettings?
    @State private var loadError = false
    @State private var loadErrorMessage = ""

    var body: some View {
        Group {
            if let settings {
                TabView {
                    ReadOnlyHooksTab(settings: settings)
                        .tabItem { Label("Hooks", systemImage: "bell") }
                    ReadOnlyPermissionsTab(settings: settings)
                        .tabItem { Label("Permissions", systemImage: "lock.shield") }
                    ReadOnlyEnvVarsTab(settings: settings)
                        .tabItem { Label("Environment", systemImage: "terminal") }
                    ReadOnlyPluginsTab(settings: settings)
                        .tabItem { Label("Plugins", systemImage: "puzzlepiece.extension") }
                }
            } else if loadError {
                ContentUnavailableView {
                    Label("Cannot Read Settings", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(loadErrorMessage.isEmpty
                         ? "The settings file could not be read."
                         : loadErrorMessage)
                } actions: {
                    Button("Retry") { loadSettings() }
                }
            } else {
                ContentUnavailableView(
                    "No Settings File",
                    systemImage: "doc.questionmark",
                    description: Text("This project has no settings configured yet.")
                )
            }
        }
        .navigationTitle(title)
        .overlay(alignment: .top) {
            if settings != nil {
                HStack {
                    Image(systemName: "eye")
                        .foregroundStyle(.blue)
                    Text("Read-only \u{2014} add this project to edit its settings")
                        .font(.callout)
                }
                .padding(8)
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                .padding(.top, 8)
            }
        }
        .onAppear { loadSettings() }
    }

    private func loadSettings() {
        let settingsPath = "\(projectPath)/.claude/settings.json"
        guard FileManager.default.fileExists(atPath: settingsPath) else { return }

        let url = URL(fileURLWithPath: settingsPath)
        do {
            let data = try Data(contentsOf: url)
            settings = try ClaudeSettings.decode(from: data)
            loadError = false
            loadErrorMessage = ""
        } catch {
            settings = nil
            loadError = true
            loadErrorMessage = error.localizedDescription
        }
    }
}

// MARK: - Read-Only Hooks Tab

private struct ReadOnlyHooksTab: View {
    let settings: ClaudeSettings

    var body: some View {
        Form {
            ForEach(ClaudeSettings.knownHookEvents, id: \.self) { event in
                Section(event) {
                    let groups = settings.hooks[event] ?? []
                    if groups.isEmpty {
                        Text("No hooks configured")
                            .foregroundStyle(.secondary)
                            .font(.callout)
                    } else {
                        ForEach(groups) { group in
                            ForEach(group.hooks) { hook in
                                Text(hook.command)
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Read-Only Permissions Tab

private struct ReadOnlyPermissionsTab: View {
    let settings: ClaudeSettings

    var body: some View {
        Form {
            Section("Default Mode") {
                Text(settings.permissions.defaultMode ?? "default")
                    .font(.system(.body, design: .monospaced))
            }
            readOnlyList("Allow", items: settings.permissions.allow)
            readOnlyList("Deny", items: settings.permissions.deny)
            readOnlyList("Ask", items: settings.permissions.ask)
        }
        .formStyle(.grouped)
    }

    private func readOnlyList(_ title: String, items: [String]) -> some View {
        Section(title) {
            if items.isEmpty {
                Text("No patterns configured")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } else {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
        }
    }
}

// MARK: - Read-Only Environment Variables Tab

private struct ReadOnlyEnvVarsTab: View {
    let settings: ClaudeSettings

    var body: some View {
        Form {
            Section("Environment Variables") {
                if settings.env.isEmpty {
                    Text("No environment variables configured")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(settings.env.keys.sorted(), id: \.self) { key in
                        HStack {
                            Text(key)
                                .font(.system(.body, design: .monospaced))
                                .frame(minWidth: 150, alignment: .leading)
                            Text(settings.env[key] ?? "")
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Read-Only Plugins Tab

private struct ReadOnlyPluginsTab: View {
    let settings: ClaudeSettings

    var body: some View {
        Form {
            Section("Enabled Plugins") {
                let plugins = settings.enabledPlugins.keys.sorted()
                if plugins.isEmpty {
                    Text("No plugins configured")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(plugins, id: \.self) { key in
                        HStack {
                            Text(key)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                            Spacer()
                            let enabled = settings.enabledPlugins[key] ?? false
                            Image(systemName: enabled ? "checkmark.circle.fill" : "xmark.circle")
                                .foregroundStyle(enabled ? .green : .secondary)
                        }
                    }
                }
            }

            Section("Extra Known Marketplaces") {
                let marketplaces = settings.extraKnownMarketplaces.keys.sorted()
                if marketplaces.isEmpty {
                    Text("No extra marketplaces configured")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(marketplaces, id: \.self) { name in
                        Text(name)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}
