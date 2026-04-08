import Foundation
import Observation
import AppKit

@Observable
@MainActor
final class SettingsStore {
    var machineSettingsManager: SettingsFileManager
    var globalConfigManager: GlobalConfigFileManager
    var projectManagers: [ProjectEntry] = []
    var discoveredProjects: [DiscoveredProject] = []

    struct ProjectEntry: Identifiable, Equatable {
        let id: String
        let name: String
        let path: String
        let sharedManager: SettingsFileManager
        let localManager: SettingsFileManager

        static func == (lhs: ProjectEntry, rhs: ProjectEntry) -> Bool { lhs.id == rhs.id }

        init(path: String, sharedManager: SettingsFileManager, localManager: SettingsFileManager) {
            self.id = path
            self.name = URL(fileURLWithPath: path).lastPathComponent
            self.path = path
            self.sharedManager = sharedManager
            self.localManager = localManager
        }

        var sharedSettingsPath: String { "\(path)/.claude/settings.json" }
        var localSettingsPath: String { "\(path)/.claude/settings.local.json" }
        var sharedMcpPath: String { "\(path)/.mcp.json" }
        var agentsPath: String { "\(path)/.claude/agents" }
        var skillsPath: String { "\(path)/.claude/skills" }
        var hooksPath: String { "\(path)/.claude/hooks" }
        var rulesPath: String { "\(path)/.claude/rules" }
        var outputStylesPath: String { "\(path)/.claude/output-styles" }
        var rootInstructionsPath: String { "\(path)/CLAUDE.md" }
        var dotClaudeInstructionsPath: String { "\(path)/.claude/CLAUDE.md" }
        var localInstructionsPath: String { "\(path)/CLAUDE.local.md" }
    }

    struct DiscoveredProject: Identifiable, Equatable {
        let id: String
        let name: String
        let path: String

        init(path: String) {
            self.id = path
            self.name = URL(fileURLWithPath: path).lastPathComponent
            self.path = path
        }
    }

    private static let customProjectsKey = "customProjectPaths"
    private let home = FileManager.default.homeDirectoryForCurrentUser.path

    var machineSettingsPath: String { "\(home)/.claude/settings.json" }
    var machineGlobalConfigPath: String { "\(home)/.claude.json" }
    var machineAgentsPath: String { "\(home)/.claude/agents" }
    var machineSkillsPath: String { "\(home)/.claude/skills" }
    var machineHooksPath: String { "\(home)/.claude/hooks" }
    var machineRulesPath: String { "\(home)/.claude/rules" }
    var machineOutputStylesPath: String { "\(home)/.claude/output-styles" }
    var machineInstructionsPath: String { "\(home)/.claude/CLAUDE.md" }
    var machinePluginsPath: String { "\(home)/.claude/plugins" }

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        self.machineSettingsManager = SettingsFileManager(filePath: "\(home)/.claude/settings.json")
        self.globalConfigManager = GlobalConfigFileManager(filePath: "\(home)/.claude.json")
        loadProjects()
    }

    func loadProjects() {
        let custom = UserDefaults.standard.stringArray(forKey: Self.customProjectsKey) ?? []

        let managedPaths = custom.sorted()
        projectManagers = managedPaths.map { path in
            let sharedManager = SettingsFileManager(filePath: "\(path)/.claude/settings.json")
            let localManager = SettingsFileManager(filePath: "\(path)/.claude/settings.local.json")
            return ProjectEntry(path: path, sharedManager: sharedManager, localManager: localManager)
        }

        refreshDiscovery()
    }

    func refreshDiscovery() {
        let customPaths = Set(UserDefaults.standard.stringArray(forKey: Self.customProjectsKey) ?? [])
        Task.detached(priority: .userInitiated) { [weak self] in
            let discovered = Set(ProjectDiscovery.discoverProjects())
            let discoveredOnly = discovered.subtracting(customPaths).sorted()
            let projects = discoveredOnly.map { DiscoveredProject(path: $0) }
            await MainActor.run {
                self?.discoveredProjects = projects
            }
        }
    }

    func addProject() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a project directory"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let path = url.path
        guard !projectManagers.contains(where: { $0.path == path }) else { return }

        var custom = UserDefaults.standard.stringArray(forKey: Self.customProjectsKey) ?? []
        if !custom.contains(path) {
            custom.append(path)
            UserDefaults.standard.set(custom, forKey: Self.customProjectsKey)
        }

        let sharedManager = SettingsFileManager(filePath: "\(path)/.claude/settings.json")
        let localManager = SettingsFileManager(filePath: "\(path)/.claude/settings.local.json")
        let entry = ProjectEntry(path: path, sharedManager: sharedManager, localManager: localManager)
        projectManagers.append(entry)
        projectManagers.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        discoveredProjects.removeAll { $0.path == path }
    }

    func promoteDiscoveredProject(_ project: DiscoveredProject) {
        guard !projectManagers.contains(where: { $0.path == project.path }) else { return }
        var custom = UserDefaults.standard.stringArray(forKey: Self.customProjectsKey) ?? []
        if !custom.contains(project.path) {
            custom.append(project.path)
            UserDefaults.standard.set(custom, forKey: Self.customProjectsKey)
        }

        let sharedManager = SettingsFileManager(filePath: "\(project.path)/.claude/settings.json")
        let localManager = SettingsFileManager(filePath: "\(project.path)/.claude/settings.local.json")
        let entry = ProjectEntry(path: project.path, sharedManager: sharedManager, localManager: localManager)
        projectManagers.append(entry)
        projectManagers.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        discoveredProjects.removeAll { $0.id == project.id }
    }

    func removeProject(_ entry: ProjectEntry) {
        entry.sharedManager.cleanup()
        entry.localManager.cleanup()
        var custom = UserDefaults.standard.stringArray(forKey: Self.customProjectsKey) ?? []
        custom.removeAll { $0 == entry.path }
        UserDefaults.standard.set(custom, forKey: Self.customProjectsKey)
        projectManagers.removeAll { $0.id == entry.id }
    }

    func entry(for path: String) -> ProjectEntry? {
        projectManagers.first { $0.path == path }
    }
}
