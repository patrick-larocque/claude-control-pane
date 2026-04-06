import Foundation
import Observation
import AppKit

@Observable
@MainActor
final class SettingsStore {
    var globalManager: SettingsFileManager
    var projectManagers: [ProjectEntry] = []
    var discoveredProjects: [DiscoveredProject] = []

    struct ProjectEntry: Identifiable, Equatable {
        let id: String
        let name: String
        let path: String
        let manager: SettingsFileManager

        static func == (lhs: ProjectEntry, rhs: ProjectEntry) -> Bool { lhs.id == rhs.id }

        init(path: String, manager: SettingsFileManager) {
            self.id = path
            self.name = URL(fileURLWithPath: path).lastPathComponent
            self.path = path
            self.manager = manager
        }
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

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let globalPath = "\(home)/.claude/settings.json"
        self.globalManager = SettingsFileManager(filePath: globalPath)
        loadProjects()
    }

    func loadProjects() {
        let custom = UserDefaults.standard.stringArray(forKey: Self.customProjectsKey) ?? []

        let managedPaths = custom.sorted()
        projectManagers = managedPaths.map { path in
            let settingsPath = "\(path)/.claude/settings.json"
            let manager = SettingsFileManager(filePath: settingsPath)
            return ProjectEntry(path: path, manager: manager)
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

        let settingsPath = "\(path)/.claude/settings.json"
        let manager = SettingsFileManager(filePath: settingsPath)
        let entry = ProjectEntry(path: path, manager: manager)
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

        let settingsPath = "\(project.path)/.claude/settings.json"
        let manager = SettingsFileManager(filePath: settingsPath)
        let entry = ProjectEntry(path: project.path, manager: manager)
        projectManagers.append(entry)
        projectManagers.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        discoveredProjects.removeAll { $0.id == project.id }
    }

    func removeProject(_ entry: ProjectEntry) {
        entry.manager.cleanup()
        var custom = UserDefaults.standard.stringArray(forKey: Self.customProjectsKey) ?? []
        custom.removeAll { $0 == entry.path }
        UserDefaults.standard.set(custom, forKey: Self.customProjectsKey)
        projectManagers.removeAll { $0.id == entry.id }
    }
}
