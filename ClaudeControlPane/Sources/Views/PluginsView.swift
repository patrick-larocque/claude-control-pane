import SwiftUI

struct PluginsView: View {
    @Bindable var manager: SettingsFileManager

    @State private var newPluginName = ""
    @State private var newMarketplaceName = ""
    @State private var newMarketplaceType = "github"
    @State private var newMarketplaceValue = ""
    @State private var showDuplicateWarning = false

    // MARK: - Known Marketplace Presets

    private struct MarketplacePreset {
        let marketplaceId: String
        let sourceType: String      // "github" or "git"
        let sourceValue: String     // repo or url
        let plugins: [PluginPreset]
    }

    private struct PluginPreset: Identifiable {
        var id: String { pluginId }
        let pluginId: String        // e.g. "pyright@claude-code-lsps"
        let displayName: String
    }

    private let presets: [MarketplacePreset] = [
        MarketplacePreset(
            marketplaceId: "claude-code-lsps",
            sourceType: "github",
            sourceValue: "boostvolt/claude-code-lsps",
            plugins: [
                PluginPreset(pluginId: "vtsls@claude-code-lsps", displayName: "TypeScript / JavaScript (vtsls)"),
                PluginPreset(pluginId: "pyright@claude-code-lsps", displayName: "Python (Pyright)"),
                PluginPreset(pluginId: "gopls@claude-code-lsps", displayName: "Go (gopls)"),
                PluginPreset(pluginId: "rust-analyzer@claude-code-lsps", displayName: "Rust (rust-analyzer)"),
                PluginPreset(pluginId: "clangd@claude-code-lsps", displayName: "C / C++ (clangd)"),
                PluginPreset(pluginId: "jdtls@claude-code-lsps", displayName: "Java (JDT.LS)"),
                PluginPreset(pluginId: "omnisharp@claude-code-lsps", displayName: "C# (OmniSharp)"),
                PluginPreset(pluginId: "intelephense@claude-code-lsps", displayName: "PHP (Intelephense)"),
                PluginPreset(pluginId: "kotlin-language-server@claude-code-lsps", displayName: "Kotlin"),
                PluginPreset(pluginId: "solargraph@claude-code-lsps", displayName: "Ruby (Solargraph)"),
                PluginPreset(pluginId: "vscode-html-css@claude-code-lsps", displayName: "HTML / CSS"),
            ]
        ),
        MarketplacePreset(
            marketplaceId: "astral-sh",
            sourceType: "github",
            sourceValue: "astral-sh/claude-code-plugins",
            plugins: [
                PluginPreset(pluginId: "astral@astral-sh", displayName: "Astral (uv, ty, ruff)"),
            ]
        ),
        MarketplacePreset(
            marketplaceId: "superpowers-marketplace",
            sourceType: "github",
            sourceValue: "obra/superpowers-marketplace",
            plugins: [
                PluginPreset(pluginId: "superpowers@superpowers-marketplace", displayName: "Superpowers"),
            ]
        ),
    ]

    var body: some View {
        Form {
            quickSetupSection
            pluginsSection
            marketplacesSection
            addMarketplaceSection
        }
        .formStyle(.grouped)
    }

    // MARK: - Quick Setup

    @ViewBuilder
    private var quickSetupSection: some View {
        ForEach(presets, id: \.marketplaceId) { preset in
            Section {
                ForEach(preset.plugins) { plugin in
                    HStack {
                        let enabled = manager.settings.enabledPlugins[plugin.pluginId] == true
                        Toggle(plugin.displayName, isOn: Binding(
                            get: { enabled },
                            set: { newValue in
                                togglePresetPlugin(plugin.pluginId, on: newValue, preset: preset)
                            }
                        ))
                        if enabled {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                    }
                }
            } header: {
                Text(presetHeader(preset))
            } footer: {
                Text(presetFooter(preset))
            }
        }
    }

    private func presetHeader(_ preset: MarketplacePreset) -> String {
        switch preset.marketplaceId {
        case "claude-code-lsps": return "Code Intelligence (LSP)"
        case "astral-sh": return "Python Tooling"
        case "superpowers-marketplace": return "Frameworks"
        default: return preset.marketplaceId
        }
    }

    private func presetFooter(_ preset: MarketplacePreset) -> String {
        switch preset.marketplaceId {
        case "claude-code-lsps":
            return "From boostvolt/claude-code-lsps. Enables jump-to-definition, find-references, and real-time diagnostics. Requires ENABLE_LSP_TOOL=1 env var."
        case "astral-sh":
            return "From astral-sh/claude-code-plugins. Skills for uv, ty, and ruff. Requires uvx."
        case "superpowers-marketplace":
            return "From obra/superpowers-marketplace. Agentic skills framework for software development."
        default:
            return "From \(preset.sourceValue)."
        }
    }

    // MARK: - Enabled Plugins

    @ViewBuilder
    private var pluginsSection: some View {
        Section {
            let plugins = manager.settings.enabledPlugins.keys.sorted()
            if plugins.isEmpty {
                Text("No plugins configured")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } else {
                ForEach(plugins, id: \.self) { pluginKey in
                    HStack {
                        Toggle(
                            pluginKey,
                            isOn: Binding(
                                get: { manager.settings.enabledPlugins[pluginKey] ?? false },
                                set: { newValue in
                                    manager.updateSettings { $0.enabledPlugins[pluginKey] = newValue }
                                }
                            )
                        )
                        .font(.system(.body, design: .monospaced))
                        Button(role: .destructive) {
                            manager.updateSettings { $0.enabledPlugins.removeValue(forKey: pluginKey) }
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }

            HStack {
                TextField("plugin-name@marketplace", text: $newPluginName)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .onSubmit { addPlugin() }
                    .onChange(of: newPluginName) { showDuplicateWarning = false }
                Button("Add") { addPlugin() }
                    .disabled(newPluginName.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if showDuplicateWarning {
                Text("Plugin already exists")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            if !newPluginName.isEmpty && !newPluginName.contains("@") {
                Text("Format: plugin-name@marketplace-name")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("All Enabled Plugins")
        } footer: {
            Text("Format: plugin-name@marketplace-name. Toggle to disable without removing.")
        }
    }

    // MARK: - Marketplaces

    @ViewBuilder
    private var marketplacesSection: some View {
        Section {
            let marketplaces = manager.settings.extraKnownMarketplaces.keys.sorted()
            if marketplaces.isEmpty {
                Text("No extra marketplaces configured")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } else {
                ForEach(marketplaces, id: \.self) { name in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(name)
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.medium)
                            Spacer()
                            Button(role: .destructive) {
                                manager.updateSettings { $0.extraKnownMarketplaces.removeValue(forKey: name) }
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                        if let value = manager.settings.extraKnownMarketplaces[name] {
                            Text(marketplaceSummary(value))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        } header: {
            Text("Extra Known Marketplaces")
        } footer: {
            Text("Marketplace sources that provide installable plugins.")
        }
    }

    // MARK: - Add Marketplace

    @ViewBuilder
    private var addMarketplaceSection: some View {
        Section("Add Marketplace") {
            TextField("Marketplace name", text: $newMarketplaceName)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))

            Picker("Source type", selection: $newMarketplaceType) {
                Text("GitHub repo").tag("github")
                Text("Git URL").tag("git")
                Text("npm package").tag("npm")
            }

            TextField(sourcePlaceholder, text: $newMarketplaceValue)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))

            Button("Add Marketplace") { addMarketplace() }
                .disabled(
                    newMarketplaceName.trimmingCharacters(in: .whitespaces).isEmpty
                    || newMarketplaceValue.trimmingCharacters(in: .whitespaces).isEmpty
                )
        }
    }

    private var sourcePlaceholder: String {
        switch newMarketplaceType {
        case "github": return "owner/repo"
        case "git": return "https://github.com/owner/repo.git"
        case "npm": return "package-name"
        default: return "source value"
        }
    }

    // MARK: - Actions

    private func togglePresetPlugin(_ pluginId: String, on: Bool, preset: MarketplacePreset) {
        manager.updateSettings { settings in
            if on {
                // Ensure the marketplace is registered
                if settings.extraKnownMarketplaces[preset.marketplaceId] == nil {
                    let sourceDict: [String: Any]
                    switch preset.sourceType {
                    case "git":
                        sourceDict = ["source": ["source": "git", "url": preset.sourceValue]]
                    default:
                        sourceDict = ["source": ["source": "github", "repo": preset.sourceValue]]
                    }
                    settings.extraKnownMarketplaces[preset.marketplaceId] = AnyCodableValue.from(sourceDict)
                }
                settings.enabledPlugins[pluginId] = true
            } else {
                settings.enabledPlugins[pluginId] = false
            }
        }
    }

    private func addPlugin() {
        let trimmed = newPluginName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard manager.settings.enabledPlugins[trimmed] == nil else {
            showDuplicateWarning = true
            return
        }
        showDuplicateWarning = false
        manager.updateSettings { $0.enabledPlugins[trimmed] = true }
        newPluginName = ""
    }

    private func addMarketplace() {
        let name = newMarketplaceName.trimmingCharacters(in: .whitespaces)
        let value = newMarketplaceValue.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !value.isEmpty else { return }

        let sourceDict: [String: Any]
        switch newMarketplaceType {
        case "github":
            sourceDict = ["source": ["source": "github", "repo": value]]
        case "git":
            sourceDict = ["source": ["source": "git", "url": value]]
        case "npm":
            sourceDict = ["source": ["source": "npm", "package": value]]
        default:
            return
        }

        let wrapped = AnyCodableValue.from(sourceDict)
        manager.updateSettings { $0.extraKnownMarketplaces[name] = wrapped }
        newMarketplaceName = ""
        newMarketplaceValue = ""
    }

    // MARK: - Helpers

    private func marketplaceSummary(_ value: AnyCodableValue) -> String {
        guard case .dictionary(let dict) = value,
              case .dictionary(let source)? = dict["source"] else {
            return "unknown source"
        }
        if case .string(let type)? = source["source"] {
            if case .string(let repo)? = source["repo"] {
                return "\(type): \(repo)"
            }
            if case .string(let url)? = source["url"] {
                return "\(type): \(url)"
            }
            if case .string(let pkg)? = source["package"] {
                return "\(type): \(pkg)"
            }
            return type
        }
        return "configured"
    }
}
