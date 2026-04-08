import SwiftUI

struct ContentView: View {
    @State private var store = SettingsStore()
    @State private var selection: SidebarItem? = .machineSettings

    var body: some View {
        NavigationSplitView {
            SidebarView(store: store, selection: $selection)
        } detail: {
            if let selection {
                switch selection {
                case .machineSettings:
                    SettingsDetailView(
                        manager: store.machineSettingsManager,
                        title: "Machine Settings",
                        locationSummary: "Machine-wide Claude settings used across projects on this Mac.",
                        locationPaths: [
                            .init(label: "User settings", path: store.machineSettingsPath)
                        ]
                    )
                case .machinePreferences:
                    VStack(alignment: .leading, spacing: 16) {
                        LocationInfoView(
                            title: "Global Preferences",
                            summary: "Official global-config-only keys stored in `~/.claude.json`.",
                            paths: [
                                .init(label: "Global config", path: store.machineGlobalConfigPath)
                            ]
                        )
                        GlobalConfigView(manager: store.globalConfigManager)
                    }
                    .padding()
                    .navigationTitle("Global Preferences")
                case .machineAgents:
                    VStack(alignment: .leading, spacing: 16) {
                        LocationInfoView(
                            title: "Machine Agents",
                            summary: "Subagents available across all projects on this Mac.",
                            paths: [
                                .init(label: "Agents directory", path: store.machineAgentsPath)
                            ]
                        )
                        DirectoryTextBrowserView(
                            title: "Agents",
                            directoryPath: store.machineAgentsPath,
                            summary: "Agent markdown files loaded from `~/.claude/agents`.",
                            defaultNewFileName: "new-agent",
                            templateContent: "# Agent\n",
                            allowedExtensions: ["md"]
                        )
                    }
                    .padding()
                    .navigationTitle("Machine Agents")
                case .machineSkills:
                    VStack(alignment: .leading, spacing: 16) {
                        LocationInfoView(
                            title: "Machine Skills",
                            summary: "Skills available across all projects on this Mac.",
                            paths: [
                                .init(label: "Skills directory", path: store.machineSkillsPath)
                            ]
                        )
                        SkillsBrowserView(directoryPath: store.machineSkillsPath)
                    }
                    .padding()
                    .navigationTitle("Machine Skills")
                case .machineInstructions:
                    VStack(alignment: .leading, spacing: 16) {
                        LocationInfoView(
                            title: "Machine Instructions",
                            summary: "User-scoped CLAUDE.md, rules, output styles, and hook scripts.",
                            paths: [
                                .init(label: "CLAUDE.md", path: store.machineInstructionsPath),
                                .init(label: "Rules", path: store.machineRulesPath),
                                .init(label: "Output styles", path: store.machineOutputStylesPath),
                                .init(label: "Hooks", path: store.machineHooksPath)
                            ]
                        )
                        InstructionsWorkspaceView(
                            title: "Machine Instructions",
                            summary: "",
                            files: [
                                .init(
                                    title: "~/.claude/CLAUDE.md",
                                    subtitle: "Loaded across projects for this user.",
                                    filePath: store.machineInstructionsPath,
                                    defaultContent: "# CLAUDE.md\n"
                                )
                            ],
                            rulesPath: store.machineRulesPath,
                            outputStylesPath: store.machineOutputStylesPath,
                            hooksPath: store.machineHooksPath
                        )
                    }
                    .padding()
                    .navigationTitle("Machine Instructions")
                case .plugins:
                    PluginsInventoryView(
                        settingsManager: store.machineSettingsManager,
                        pluginsPath: store.machinePluginsPath
                    )
                    .padding()
                    .navigationTitle("Plugins")
                case .diagnostics:
                    DiagnosticsView(
                        report: DiagnosticsService.generate(machineSettings: store.machineSettingsManager.settings),
                        machineSettingsPath: store.machineSettingsPath,
                        machineGlobalConfigPath: store.machineGlobalConfigPath
                    )
                    .padding()
                    .navigationTitle("Diagnostics")
                case .sharedSettings(let path):
                    if let entry = store.entry(for: path) {
                        SettingsDetailView(
                            manager: entry.sharedManager,
                            title: "\(entry.name) · Shared",
                            locationSummary: "Shared settings committed with the workspace and applied to collaborators.",
                            locationPaths: [
                                .init(label: "Shared settings", path: entry.sharedSettingsPath)
                            ]
                        )
                        .id(path)
                    }
                case .localSettings(let path):
                    if let entry = store.entry(for: path) {
                        SettingsDetailView(
                            manager: entry.localManager,
                            title: "\(entry.name) · Local",
                            locationSummary: "Local-only overrides for this workspace. This file is normally gitignored.",
                            locationPaths: [
                                .init(label: "Local settings", path: entry.localSettingsPath)
                            ]
                        )
                        .id("local-\(path)")
                    }
                case .sharedMcp(let path):
                    if let entry = store.entry(for: path) {
                        VStack(alignment: .leading, spacing: 16) {
                            LocationInfoView(
                                title: "Shared MCP",
                                summary: "Project-scoped MCP servers shared through `.mcp.json`.",
                                paths: [
                                    .init(label: "Project MCP", path: entry.sharedMcpPath)
                                ]
                            )
                            SharedMCPView(filePath: entry.sharedMcpPath)
                        }
                        .id("shared-mcp-\(path)")
                        .padding()
                        .navigationTitle("\(entry.name) · Shared MCP")
                    }
                case .localMcp(let path):
                    if let entry = store.entry(for: path) {
                        VStack(alignment: .leading, spacing: 16) {
                            LocationInfoView(
                                title: "Local MCP",
                                summary: "Local-only MCP servers for this workspace are stored inside `~/.claude.json`.",
                                paths: [
                                    .init(label: "Global config", path: store.machineGlobalConfigPath)
                                ]
                            )
                            LocalMCPView(manager: store.globalConfigManager, projectPath: entry.path)
                        }
                        .id("local-mcp-\(path)")
                        .padding()
                        .navigationTitle("\(entry.name) · Local MCP")
                    }
                case .agents(let path):
                    if let entry = store.entry(for: path) {
                        VStack(alignment: .leading, spacing: 16) {
                            LocationInfoView(
                                title: "Workspace Agents",
                                summary: "Project-scoped subagents from `.claude/agents`.",
                                paths: [
                                    .init(label: "Agents directory", path: entry.agentsPath)
                                ]
                            )
                            DirectoryTextBrowserView(
                                title: "Agents",
                                directoryPath: entry.agentsPath,
                                summary: "Workspace-specific agents.",
                                defaultNewFileName: "new-agent",
                                templateContent: "# Agent\n",
                                allowedExtensions: ["md"]
                            )
                        }
                        .id("agents-\(path)")
                        .padding()
                        .navigationTitle("\(entry.name) · Agents")
                    }
                case .skills(let path):
                    if let entry = store.entry(for: path) {
                        VStack(alignment: .leading, spacing: 16) {
                            LocationInfoView(
                                title: "Workspace Skills",
                                summary: "Project-scoped skills from `.claude/skills`.",
                                paths: [
                                    .init(label: "Skills directory", path: entry.skillsPath)
                                ]
                            )
                            SkillsBrowserView(directoryPath: entry.skillsPath)
                        }
                        .id("skills-\(path)")
                        .padding()
                        .navigationTitle("\(entry.name) · Skills")
                    }
                case .instructions(let path):
                    if let entry = store.entry(for: path) {
                        VStack(alignment: .leading, spacing: 16) {
                            LocationInfoView(
                                title: "Workspace Instructions",
                                summary: "Shared and local instruction files, rules, output styles, and hook scripts for this workspace.",
                                paths: [
                                    .init(label: "CLAUDE.md", path: entry.rootInstructionsPath),
                                    .init(label: ".claude/CLAUDE.md", path: entry.dotClaudeInstructionsPath),
                                    .init(label: "CLAUDE.local.md", path: entry.localInstructionsPath),
                                    .init(label: "Rules", path: entry.rulesPath),
                                    .init(label: "Output styles", path: entry.outputStylesPath),
                                    .init(label: "Hooks", path: entry.hooksPath)
                                ]
                            )
                            InstructionsWorkspaceView(
                                title: "Workspace Instructions",
                                summary: "",
                                files: [
                                    .init(
                                        title: "CLAUDE.md",
                                        subtitle: "Root project instructions shared with collaborators.",
                                        filePath: entry.rootInstructionsPath,
                                        defaultContent: "# CLAUDE.md\n"
                                    ),
                                    .init(
                                        title: ".claude/CLAUDE.md",
                                        subtitle: "Alternative shared instructions file inside `.claude`.",
                                        filePath: entry.dotClaudeInstructionsPath,
                                        defaultContent: "# CLAUDE.md\n"
                                    ),
                                    .init(
                                        title: "CLAUDE.local.md",
                                        subtitle: "Local-only instructions for this workspace.",
                                        filePath: entry.localInstructionsPath,
                                        defaultContent: "# CLAUDE.local.md\n"
                                    )
                                ],
                                rulesPath: entry.rulesPath,
                                outputStylesPath: entry.outputStylesPath,
                                hooksPath: entry.hooksPath
                            )
                        }
                        .id("instructions-\(path)")
                        .padding()
                        .navigationTitle("\(entry.name) · Instructions")
                    }
                case .discovered(let path):
                    if let project = store.discoveredProjects.first(where: { $0.path == path }) {
                        ReadOnlySettingsDetailView(
                            projectPath: project.path,
                            title: project.name
                        )
                        .id(path)
                    }
                }
            } else {
                Text("Select a Claude configuration surface")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .onChange(of: store.projectManagers) { _, _ in
            validateSelection()
        }
        .onChange(of: store.discoveredProjects) { _, _ in
            validateSelection()
        }
    }

    private func validateSelection() {
        guard let selection else { return }
        switch selection {
        case .machineSettings, .machinePreferences, .machineAgents, .machineSkills, .machineInstructions, .plugins, .diagnostics:
            break
        case .sharedSettings(let path), .localSettings(let path), .sharedMcp(let path), .localMcp(let path), .agents(let path), .skills(let path), .instructions(let path):
            if !store.projectManagers.contains(where: { $0.path == path }) {
                self.selection = .machineSettings
            }
        case .discovered(let path):
            if !store.discoveredProjects.contains(where: { $0.path == path }) {
                self.selection = .machineSettings
            }
        }
    }
}
