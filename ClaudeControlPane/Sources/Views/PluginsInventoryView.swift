import SwiftUI

struct PluginsInventoryView: View {
    @Bindable var settingsManager: SettingsFileManager
    let pluginsPath: String

    private var marketplacePaths: [String] {
        let marketplacesPath = URL(fileURLWithPath: pluginsPath).appendingPathComponent("marketplaces").path
        let entries = (try? FileManager.default.contentsOfDirectory(atPath: marketplacesPath)) ?? []
        return entries.sorted().map { URL(fileURLWithPath: marketplacesPath).appendingPathComponent($0).path }
    }

    private var metadataFiles: [String] {
        ["installed_plugins.json", "known_marketplaces.json", "blocklist.json"]
            .map { URL(fileURLWithPath: pluginsPath).appendingPathComponent($0).path }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                LocationInfoView(
                    title: "Installed Plugins",
                    summary: "Configured plugin flags come from settings.json. Installed marketplace content is cached under `~/.claude/plugins`.",
                    paths: [
                        .init(label: "Plugin cache root", path: pluginsPath)
                    ]
                )

                Form {
                    Section("Configured Enabled Plugins") {
                        let keys = settingsManager.settings.enabledPlugins.keys.sorted()
                        if keys.isEmpty {
                            Text("No plugins configured")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(keys, id: \.self) { key in
                                HStack {
                                    Text(key)
                                        .font(.system(.body, design: .monospaced))
                                    Spacer()
                                    Image(systemName: settingsManager.settings.enabledPlugins[key] == true ? "checkmark.circle.fill" : "xmark.circle")
                                        .foregroundStyle(settingsManager.settings.enabledPlugins[key] == true ? .green : .secondary)
                                }
                            }
                        }
                    }

                    Section("Configured Marketplaces") {
                        let keys = settingsManager.settings.extraKnownMarketplaces.keys.sorted()
                        if keys.isEmpty {
                            Text("No extra marketplaces configured")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(keys, id: \.self) { key in
                                Text(key)
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                    }
                }
                .formStyle(.grouped)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Installed Marketplace Clones")
                        .font(.headline)
                    if marketplacePaths.isEmpty {
                        Text("No marketplace clones found")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(marketplacePaths, id: \.self) { path in
                            Text(path)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Metadata Files")
                        .font(.headline)
                    ForEach(metadataFiles, id: \.self) { path in
                        Text(path)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
            }
            .padding(.bottom)
        }
    }
}
