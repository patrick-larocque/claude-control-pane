# Claude Control Pane Implementation Plan

> Historical note: this implementation plan reflects the original v1 build-out and no longer matches the app's current scope. Treat it as historical context only; use `/README.md`, `/CLAUDE.md`, and the current codebase as the active source of truth.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS SwiftUI app that lets users manage Claude Code settings (hooks, permissions, env vars) for global and project-level `settings.json` files.

**Architecture:** Swift Package with a single executable target. `NavigationSplitView` with sidebar (global + projects) and detail area (tabbed: Hooks, Permissions, Env Vars). `@Observable` store manages settings file I/O and file watching. Unknown JSON keys preserved via raw dictionary round-tripping.

**Tech Stack:** Swift 6, SwiftUI, macOS 14+, Swift Package Manager (no Xcode IDE required)

---

## File Structure

```
ClaudeControlPane/
├── Package.swift
├── Sources/
│   ├── App/
│   │   └── ClaudeControlPaneApp.swift       # @main App entry, WindowGroup
│   ├── Models/
│   │   ├── ClaudeSettings.swift             # Top-level settings struct + JSON coding
│   │   ├── PermissionsConfig.swift          # Permissions model
│   │   ├── HookConfig.swift                 # Hook/HookGroup models
│   │   └── AnyCodableValue.swift            # Dynamic JSON value type for round-tripping
│   ├── Services/
│   │   ├── SettingsFileManager.swift        # Read/write/watch a single settings.json
│   │   ├── SettingsStore.swift              # @Observable store: global + projects
│   │   └── ProjectDiscovery.swift           # Scan directories for projects
│   └── Views/
│       ├── ContentView.swift                # NavigationSplitView shell
│       ├── SidebarView.swift                # Sidebar: global + project list + add
│       ├── SettingsDetailView.swift         # TabView wrapper for detail pane
│       ├── HooksView.swift                  # Hooks tab content
│       ├── PermissionsView.swift            # Permissions tab content
│       └── EnvVarsView.swift                # Environment variables tab content
└── docs/
    └── superpowers/ ...
```

---

### Task 1: Swift Package Scaffold + App Entry Point

**Files:**
- Create: `ClaudeControlPane/Package.swift`
- Create: `ClaudeControlPane/Sources/App/ClaudeControlPaneApp.swift`
- Create: `ClaudeControlPane/Sources/Views/ContentView.swift`

- [ ] **Step 1: Create Package.swift**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ClaudeControlPane",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "ClaudeControlPane",
            path: "Sources"
        )
    ]
)
```

- [ ] **Step 2: Create the app entry point**

Create `ClaudeControlPane/Sources/App/ClaudeControlPaneApp.swift`:

```swift
import SwiftUI

@main
struct ClaudeControlPaneApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}
```

- [ ] **Step 3: Create a placeholder ContentView**

Create `ClaudeControlPane/Sources/Views/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            List {
                Text("Global Settings")
            }
            .navigationTitle("Claude Control Pane")
        } detail: {
            Text("Select a settings scope")
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 700, minHeight: 500)
    }
}
```

- [ ] **Step 4: Build and verify it compiles**

```bash
cd ClaudeControlPane && swift build 2>&1
```

Expected: Build succeeds with no errors.

- [ ] **Step 5: Commit**

```bash
git add ClaudeControlPane/
git commit -m "feat: scaffold Swift package with app entry point and placeholder UI"
```

---

### Task 2: AnyCodableValue for JSON Round-Tripping

**Files:**
- Create: `ClaudeControlPane/Sources/Models/AnyCodableValue.swift`

This type wraps arbitrary JSON values so the app can decode, preserve, and re-encode unknown fields without data loss.

- [ ] **Step 1: Create AnyCodableValue**

Create `ClaudeControlPane/Sources/Models/AnyCodableValue.swift`:

```swift
import Foundation

enum AnyCodableValue: Sendable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([AnyCodableValue])
    case dictionary([String: AnyCodableValue])
    case null

    static func from(_ any: Any) -> AnyCodableValue {
        switch any {
        case let s as String: return .string(s)
        case let b as Bool: return .bool(b)
        case let i as Int: return .int(i)
        case let d as Double: return .double(d)
        case let arr as [Any]: return .array(arr.map { AnyCodableValue.from($0) })
        case let dict as [String: Any]: return .dictionary(dict.mapValues { AnyCodableValue.from($0) })
        default: return .null
        }
    }

    func toAny() -> Any {
        switch self {
        case .string(let s): return s
        case .int(let i): return i
        case .double(let d): return d
        case .bool(let b): return b
        case .array(let arr): return arr.map { $0.toAny() }
        case .dictionary(let dict): return dict.mapValues { $0.toAny() }
        case .null: return NSNull()
        }
    }
}

extension AnyCodableValue: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else if let i = try? container.decode(Int.self) {
            self = .int(i)
        } else if let d = try? container.decode(Double.self) {
            self = .double(d)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else if let arr = try? container.decode([AnyCodableValue].self) {
            self = .array(arr)
        } else if let dict = try? container.decode([String: AnyCodableValue].self) {
            self = .dictionary(dict)
        } else {
            self = .null
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .int(let i): try container.encode(i)
        case .double(let d): try container.encode(d)
        case .bool(let b): try container.encode(b)
        case .array(let arr): try container.encode(arr)
        case .dictionary(let dict): try container.encode(dict)
        case .null: try container.encodeNil()
        }
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
cd ClaudeControlPane && swift build 2>&1
```

Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add ClaudeControlPane/Sources/Models/AnyCodableValue.swift
git commit -m "feat: add AnyCodableValue for lossless JSON round-tripping"
```

---

### Task 3: Settings Data Models

**Files:**
- Create: `ClaudeControlPane/Sources/Models/HookConfig.swift`
- Create: `ClaudeControlPane/Sources/Models/PermissionsConfig.swift`
- Create: `ClaudeControlPane/Sources/Models/ClaudeSettings.swift`

- [ ] **Step 1: Create HookConfig**

Create `ClaudeControlPane/Sources/Models/HookConfig.swift`:

```swift
import Foundation

struct Hook: Codable, Sendable, Equatable, Identifiable {
    var id = UUID()
    var type: String
    var command: String

    enum CodingKeys: String, CodingKey {
        case type, command
    }

    init(type: String = "command", command: String = "") {
        self.id = UUID()
        self.type = type
        self.command = command
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.type = try container.decode(String.self, forKey: .type)
        self.command = try container.decode(String.self, forKey: .command)
    }
}

struct HookGroup: Codable, Sendable, Equatable, Identifiable {
    var id = UUID()
    var hooks: [Hook]

    enum CodingKeys: String, CodingKey {
        case hooks
    }

    init(hooks: [Hook] = []) {
        self.id = UUID()
        self.hooks = hooks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.hooks = try container.decode([Hook].self, forKey: .hooks)
    }
}
```

- [ ] **Step 2: Create PermissionsConfig**

Create `ClaudeControlPane/Sources/Models/PermissionsConfig.swift`:

```swift
import Foundation

struct PermissionsConfig: Codable, Sendable, Equatable {
    var defaultMode: String?
    var allow: [String]
    var deny: [String]
    var ask: [String]

    init(defaultMode: String? = nil, allow: [String] = [], deny: [String] = [], ask: [String] = []) {
        self.defaultMode = defaultMode
        self.allow = allow
        self.deny = deny
        self.ask = ask
    }

    enum CodingKeys: String, CodingKey {
        case defaultMode, allow, deny, ask
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.defaultMode = try container.decodeIfPresent(String.self, forKey: .defaultMode)
        self.allow = (try? container.decode([String].self, forKey: .allow)) ?? []
        self.deny = (try? container.decode([String].self, forKey: .deny)) ?? []
        self.ask = (try? container.decode([String].self, forKey: .ask)) ?? []
    }
}
```

- [ ] **Step 3: Create ClaudeSettings**

Create `ClaudeControlPane/Sources/Models/ClaudeSettings.swift`:

```swift
import Foundation

struct ClaudeSettings: Sendable, Equatable {
    var permissions: PermissionsConfig
    var hooks: [String: [HookGroup]]
    var env: [String: String]
    var extraFields: [String: AnyCodableValue]

    static let knownHookEvents = ["Stop", "PreToolUse", "PostToolUse", "Notification", "SubagentStop"]

    init(
        permissions: PermissionsConfig = PermissionsConfig(),
        hooks: [String: [HookGroup]] = [:],
        env: [String: String] = [:],
        extraFields: [String: AnyCodableValue] = [:]
    ) {
        self.permissions = permissions
        self.hooks = hooks
        self.env = env
        self.extraFields = extraFields
    }
}

extension ClaudeSettings {
    static func decode(from data: Data) throws -> ClaudeSettings {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let decoder = JSONDecoder()

        var permissions = PermissionsConfig()
        if let permDict = json["permissions"] {
            let permData = try JSONSerialization.data(withJSONObject: permDict)
            permissions = try decoder.decode(PermissionsConfig.self, from: permData)
        }

        var hooks: [String: [HookGroup]] = [:]
        if let hooksDict = json["hooks"] as? [String: Any] {
            for (event, value) in hooksDict {
                let hookData = try JSONSerialization.data(withJSONObject: value)
                hooks[event] = try decoder.decode([HookGroup].self, from: hookData)
            }
        }

        var env: [String: String] = [:]
        if let envDict = json["env"] as? [String: String] {
            env = envDict
        }

        let knownKeys: Set<String> = ["permissions", "hooks", "env"]
        var extraFields: [String: AnyCodableValue] = [:]
        for (key, value) in json where !knownKeys.contains(key) {
            extraFields[key] = AnyCodableValue.from(value)
        }

        return ClaudeSettings(
            permissions: permissions,
            hooks: hooks,
            env: env,
            extraFields: extraFields
        )
    }

    func encode() throws -> Data {
        var dict: [String: Any] = [:]

        for (key, value) in extraFields {
            dict[key] = value.toAny()
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let permData = try encoder.encode(permissions)
        let permObj = try JSONSerialization.jsonObject(with: permData)
        dict["permissions"] = permObj

        if !hooks.isEmpty {
            var hooksDict: [String: Any] = [:]
            for (event, groups) in hooks {
                let groupData = try encoder.encode(groups)
                hooksDict[event] = try JSONSerialization.jsonObject(with: groupData)
            }
            dict["hooks"] = hooksDict
        }

        if !env.isEmpty {
            dict["env"] = env
        }

        return try JSONSerialization.data(
            withJSONObject: dict,
            options: [.prettyPrinted, .sortedKeys]
        )
    }
}
```

- [ ] **Step 4: Build to verify**

```bash
cd ClaudeControlPane && swift build 2>&1
```

Expected: Build succeeds.

- [ ] **Step 5: Commit**

```bash
git add ClaudeControlPane/Sources/Models/
git commit -m "feat: add settings data models with lossless JSON round-tripping"
```

---

### Task 4: SettingsFileManager — Read, Write, Watch

**Files:**
- Create: `ClaudeControlPane/Sources/Services/SettingsFileManager.swift`

- [ ] **Step 1: Create SettingsFileManager**

Create `ClaudeControlPane/Sources/Services/SettingsFileManager.swift`:

```swift
import Foundation
import Observation

@Observable
@MainActor
final class SettingsFileManager {
    let filePath: String
    private(set) var settings: ClaudeSettings
    private(set) var hasError: Bool = false
    private(set) var errorMessage: String = ""

    private var fileDescriptor: Int32 = -1
    private var dispatchSource: DispatchSourceFileSystemObject?
    private var debounceTask: Task<Void, Never>?
    private var isWriting = false

    init(filePath: String) {
        self.filePath = filePath
        self.settings = ClaudeSettings()
        loadFromDisk()
        startWatching()
    }

    deinit {
        stopWatching()
    }

    func loadFromDisk() {
        let url = URL(fileURLWithPath: filePath)
        guard FileManager.default.fileExists(atPath: filePath) else {
            self.settings = ClaudeSettings()
            self.hasError = false
            self.errorMessage = ""
            return
        }

        do {
            let data = try Data(contentsOf: url)
            self.settings = try ClaudeSettings.decode(from: data)
            self.hasError = false
            self.errorMessage = ""
        } catch {
            self.hasError = true
            self.errorMessage = "Invalid JSON: \(error.localizedDescription)"
        }
    }

    func saveToDisk() {
        do {
            let data = try settings.encode()
            let url = URL(fileURLWithPath: filePath)

            let directory = url.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            }

            isWriting = true
            try data.write(to: url, options: .atomic)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.isWriting = false
            }
            self.hasError = false
            self.errorMessage = ""
        } catch {
            self.hasError = true
            self.errorMessage = "Write failed: \(error.localizedDescription)"
        }
    }

    func updateSettings(_ transform: (inout ClaudeSettings) -> Void) {
        transform(&settings)
        saveToDisk()
    }

    private func startWatching() {
        let url = URL(fileURLWithPath: filePath)
        let dir = url.deletingLastPathComponent().path

        if !FileManager.default.fileExists(atPath: dir) {
            return
        }

        let watchPath = FileManager.default.fileExists(atPath: filePath) ? filePath : dir
        let fd = open(watchPath, O_EVTONLY)
        guard fd >= 0 else { return }
        self.fileDescriptor = fd

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename, .delete],
            queue: .main
        )

        source.setEventHandler { [weak self] in
            guard let self = self, !self.isWriting else { return }
            self.debounceTask?.cancel()
            self.debounceTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 100_000_000)
                guard !Task.isCancelled else { return }
                self?.loadFromDisk()
            }
        }

        source.setCancelHandler { [fd] in
            close(fd)
        }

        source.resume()
        self.dispatchSource = source
    }

    private func stopWatching() {
        dispatchSource?.cancel()
        dispatchSource = nil
        fileDescriptor = -1
    }
}
```

- [ ] **Step 2: Build to verify**

```bash
cd ClaudeControlPane && swift build 2>&1
```

Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add ClaudeControlPane/Sources/Services/SettingsFileManager.swift
git commit -m "feat: add SettingsFileManager with read, write, and file watching"
```

---

### Task 5: ProjectDiscovery + SettingsStore

**Files:**
- Create: `ClaudeControlPane/Sources/Services/ProjectDiscovery.swift`
- Create: `ClaudeControlPane/Sources/Services/SettingsStore.swift`

- [ ] **Step 1: Create ProjectDiscovery**

Create `ClaudeControlPane/Sources/Services/ProjectDiscovery.swift`:

```swift
import Foundation

struct ProjectDiscovery {
    static let scanDirectories = [
        "Documents", "code", "Developer", "Projects", "src"
    ]

    static func discoverProjects() -> [String] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let fm = FileManager.default
        var found: [String] = []

        for dir in scanDirectories {
            let scanPath = "\(home)/\(dir)"
            guard fm.fileExists(atPath: scanPath) else { continue }

            guard let children = try? fm.contentsOfDirectory(atPath: scanPath) else { continue }
            for child in children {
                let projectPath = "\(scanPath)/\(child)"
                let settingsPath = "\(projectPath)/.claude/settings.json"
                var isDir: ObjCBool = false
                if fm.fileExists(atPath: projectPath, isDirectory: &isDir),
                   isDir.boolValue,
                   fm.fileExists(atPath: settingsPath) {
                    found.append(projectPath)
                }
            }
        }

        return found.sorted()
    }
}
```

- [ ] **Step 2: Create SettingsStore**

Create `ClaudeControlPane/Sources/Services/SettingsStore.swift`:

```swift
import Foundation
import Observation
import AppKit

@Observable
@MainActor
final class SettingsStore {
    var globalManager: SettingsFileManager
    var projectManagers: [ProjectEntry] = []

    struct ProjectEntry: Identifiable {
        let id: String
        let name: String
        let path: String
        let manager: SettingsFileManager

        init(path: String, manager: SettingsFileManager) {
            self.id = path
            self.name = URL(fileURLWithPath: path).lastPathComponent
            self.path = path
            self.manager = manager
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
        let discovered = ProjectDiscovery.discoverProjects()
        let custom = UserDefaults.standard.stringArray(forKey: Self.customProjectsKey) ?? []
        let allPaths = Set(discovered + custom).sorted()

        projectManagers = allPaths.map { path in
            let settingsPath = "\(path)/.claude/settings.json"
            let manager = SettingsFileManager(filePath: settingsPath)
            return ProjectEntry(path: path, manager: manager)
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
    }

    func removeProject(_ entry: ProjectEntry) {
        var custom = UserDefaults.standard.stringArray(forKey: Self.customProjectsKey) ?? []
        custom.removeAll { $0 == entry.path }
        UserDefaults.standard.set(custom, forKey: Self.customProjectsKey)
        projectManagers.removeAll { $0.id == entry.id }
    }
}
```

- [ ] **Step 3: Build to verify**

```bash
cd ClaudeControlPane && swift build 2>&1
```

Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
git add ClaudeControlPane/Sources/Services/
git commit -m "feat: add project discovery and settings store"
```

---

### Task 6: Sidebar View

**Files:**
- Create: `ClaudeControlPane/Sources/Views/SidebarView.swift`
- Modify: `ClaudeControlPane/Sources/Views/ContentView.swift`

- [ ] **Step 1: Create SidebarView**

Create `ClaudeControlPane/Sources/Views/SidebarView.swift`:

```swift
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
```

- [ ] **Step 2: Update ContentView to use SidebarView and SettingsStore**

Replace `ClaudeControlPane/Sources/Views/ContentView.swift` with:

```swift
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
                }
            } else {
                Text("Select a settings scope")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 700, minHeight: 500)
    }
}
```

- [ ] **Step 3: Create placeholder SettingsDetailView**

Create `ClaudeControlPane/Sources/Views/SettingsDetailView.swift`:

```swift
import SwiftUI

struct SettingsDetailView: View {
    @Bindable var manager: SettingsFileManager
    let title: String

    var body: some View {
        TabView {
            Tab("Hooks", systemImage: "bell") {
                Text("Hooks (coming next)")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Tab("Permissions", systemImage: "lock.shield") {
                Text("Permissions (coming soon)")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Tab("Environment", systemImage: "terminal") {
                Text("Environment Variables (coming soon)")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(title)
        .overlay(alignment: .top) {
            if manager.hasError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(manager.errorMessage)
                        .font(.callout)
                }
                .padding(8)
                .background(.yellow.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                .padding(.top, 8)
            }
        }
    }
}
```

- [ ] **Step 4: Build to verify**

```bash
cd ClaudeControlPane && swift build 2>&1
```

Expected: Build succeeds.

- [ ] **Step 5: Commit**

```bash
git add ClaudeControlPane/Sources/Views/
git commit -m "feat: add sidebar, content view, and settings detail shell"
```

---

### Task 7: Hooks View

**Files:**
- Create: `ClaudeControlPane/Sources/Views/HooksView.swift`
- Modify: `ClaudeControlPane/Sources/Views/SettingsDetailView.swift`

- [ ] **Step 1: Create HooksView**

Create `ClaudeControlPane/Sources/Views/HooksView.swift`:

```swift
import SwiftUI

struct HooksView: View {
    @Bindable var manager: SettingsFileManager

    private var hasSoundHook: Bool {
        guard let groups = manager.settings.hooks["Stop"] else { return false }
        return groups.contains { group in
            group.hooks.contains { $0.command.contains("afplay") }
        }
    }

    var body: some View {
        Form {
            Section {
                Toggle("Play sound when Claude finishes", isOn: Binding(
                    get: { hasSoundHook },
                    set: { enabled in
                        manager.updateSettings { settings in
                            if enabled {
                                let hook = Hook(type: "command", command: "afplay /System/Library/Sounds/Funk.aiff")
                                let group = HookGroup(hooks: [hook])
                                if settings.hooks["Stop"] != nil {
                                    settings.hooks["Stop"]!.append(group)
                                } else {
                                    settings.hooks["Stop"] = [group]
                                }
                            } else {
                                settings.hooks["Stop"]?.removeAll { group in
                                    group.hooks.contains { $0.command.contains("afplay") }
                                }
                                if settings.hooks["Stop"]?.isEmpty == true {
                                    settings.hooks.removeValue(forKey: "Stop")
                                }
                            }
                        }
                    }
                ))
            } header: {
                Text("Quick Settings")
            }

            ForEach(ClaudeSettings.knownHookEvents, id: \.self) { event in
                Section {
                    let groups = manager.settings.hooks[event] ?? []
                    if groups.isEmpty {
                        Text("No hooks configured")
                            .foregroundStyle(.secondary)
                            .font(.callout)
                    } else {
                        ForEach(Array(groups.enumerated()), id: \.element.id) { groupIndex, group in
                            ForEach(Array(group.hooks.enumerated()), id: \.element.id) { hookIndex, hook in
                                HookRowView(
                                    command: hook.command,
                                    onUpdate: { newCommand in
                                        manager.updateSettings { settings in
                                            settings.hooks[event]?[groupIndex].hooks[hookIndex].command = newCommand
                                        }
                                    },
                                    onDelete: {
                                        manager.updateSettings { settings in
                                            settings.hooks[event]?[groupIndex].hooks.remove(at: hookIndex)
                                            if settings.hooks[event]?[groupIndex].hooks.isEmpty == true {
                                                settings.hooks[event]?.remove(at: groupIndex)
                                            }
                                            if settings.hooks[event]?.isEmpty == true {
                                                settings.hooks.removeValue(forKey: event)
                                            }
                                        }
                                    }
                                )
                            }
                        }
                    }

                    Button("Add Hook") {
                        manager.updateSettings { settings in
                            let hook = Hook(type: "command", command: "")
                            let group = HookGroup(hooks: [hook])
                            if settings.hooks[event] != nil {
                                settings.hooks[event]!.append(group)
                            } else {
                                settings.hooks[event] = [group]
                            }
                        }
                    }
                    .buttonStyle(.borderless)
                } header: {
                    Text(event)
                }
            }
        }
        .formStyle(.grouped)
    }
}

struct HookRowView: View {
    @State var command: String
    var onUpdate: (String) -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack {
            TextField("Command", text: $command)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .onSubmit {
                    onUpdate(command)
                }
            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
    }
}
```

- [ ] **Step 2: Wire HooksView into SettingsDetailView**

In `ClaudeControlPane/Sources/Views/SettingsDetailView.swift`, replace the Hooks tab placeholder:

Change:
```swift
            Tab("Hooks", systemImage: "bell") {
                Text("Hooks (coming next)")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
```

To:
```swift
            Tab("Hooks", systemImage: "bell") {
                HooksView(manager: manager)
            }
```

- [ ] **Step 3: Build to verify**

```bash
cd ClaudeControlPane && swift build 2>&1
```

Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
git add ClaudeControlPane/Sources/Views/HooksView.swift ClaudeControlPane/Sources/Views/SettingsDetailView.swift
git commit -m "feat: add hooks view with sound hook toggle and per-event editing"
```

---

### Task 8: Permissions View

**Files:**
- Create: `ClaudeControlPane/Sources/Views/PermissionsView.swift`
- Modify: `ClaudeControlPane/Sources/Views/SettingsDetailView.swift`

- [ ] **Step 1: Create PermissionsView**

Create `ClaudeControlPane/Sources/Views/PermissionsView.swift`:

```swift
import SwiftUI

struct PermissionsView: View {
    @Bindable var manager: SettingsFileManager

    private let modeOptions = ["default", "bypassPermissions", "plan", "acceptEdits"]

    var body: some View {
        Form {
            Section("Default Mode") {
                Picker("Permission Mode", selection: Binding(
                    get: { manager.settings.permissions.defaultMode ?? "default" },
                    set: { newValue in
                        manager.updateSettings { settings in
                            settings.permissions.defaultMode = newValue == "default" ? nil : newValue
                        }
                    }
                )) {
                    ForEach(modeOptions, id: \.self) { mode in
                        Text(mode).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            PermissionListSection(
                title: "Allow",
                items: manager.settings.permissions.allow,
                onAdd: { pattern in
                    manager.updateSettings { $0.permissions.allow.append(pattern) }
                },
                onRemove: { index in
                    manager.updateSettings { $0.permissions.allow.remove(at: index) }
                },
                onUpdate: { index, value in
                    manager.updateSettings { $0.permissions.allow[index] = value }
                }
            )

            PermissionListSection(
                title: "Deny",
                items: manager.settings.permissions.deny,
                onAdd: { pattern in
                    manager.updateSettings { $0.permissions.deny.append(pattern) }
                },
                onRemove: { index in
                    manager.updateSettings { $0.permissions.deny.remove(at: index) }
                },
                onUpdate: { index, value in
                    manager.updateSettings { $0.permissions.deny[index] = value }
                }
            )

            PermissionListSection(
                title: "Ask",
                items: manager.settings.permissions.ask,
                onAdd: { pattern in
                    manager.updateSettings { $0.permissions.ask.append(pattern) }
                },
                onRemove: { index in
                    manager.updateSettings { $0.permissions.ask.remove(at: index) }
                },
                onUpdate: { index, value in
                    manager.updateSettings { $0.permissions.ask[index] = value }
                }
            )
        }
        .formStyle(.grouped)
    }
}

struct PermissionListSection: View {
    let title: String
    let items: [String]
    var onAdd: (String) -> Void
    var onRemove: (Int) -> Void
    var onUpdate: (Int, String) -> Void

    @State private var newItem = ""

    var body: some View {
        Section(title) {
            if items.isEmpty {
                Text("No patterns configured")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } else {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack {
                        PermissionItemField(
                            value: item,
                            onCommit: { newValue in onUpdate(index, newValue) }
                        )
                        Button(role: .destructive) {
                            onRemove(index)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }

            HStack {
                TextField("e.g. Bash(git:*)", text: $newItem)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .onSubmit {
                        addItem()
                    }
                Button("Add") {
                    addItem()
                }
                .disabled(newItem.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func addItem() {
        let trimmed = newItem.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        onAdd(trimmed)
        newItem = ""
    }
}

struct PermissionItemField: View {
    @State var value: String
    var onCommit: (String) -> Void

    init(value: String, onCommit: @escaping (String) -> Void) {
        self._value = State(initialValue: value)
        self.onCommit = onCommit
    }

    var body: some View {
        TextField("Pattern", text: $value)
            .textFieldStyle(.roundedBorder)
            .font(.system(.body, design: .monospaced))
            .onSubmit {
                onCommit(value)
            }
    }
}
```

- [ ] **Step 2: Wire PermissionsView into SettingsDetailView**

In `ClaudeControlPane/Sources/Views/SettingsDetailView.swift`, replace the Permissions tab placeholder:

Change:
```swift
            Tab("Permissions", systemImage: "lock.shield") {
                Text("Permissions (coming soon)")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
```

To:
```swift
            Tab("Permissions", systemImage: "lock.shield") {
                PermissionsView(manager: manager)
            }
```

- [ ] **Step 3: Build to verify**

```bash
cd ClaudeControlPane && swift build 2>&1
```

Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
git add ClaudeControlPane/Sources/Views/PermissionsView.swift ClaudeControlPane/Sources/Views/SettingsDetailView.swift
git commit -m "feat: add permissions view with mode picker and editable allow/deny/ask lists"
```

---

### Task 9: Environment Variables View

**Files:**
- Create: `ClaudeControlPane/Sources/Views/EnvVarsView.swift`
- Modify: `ClaudeControlPane/Sources/Views/SettingsDetailView.swift`

- [ ] **Step 1: Create EnvVarsView**

Create `ClaudeControlPane/Sources/Views/EnvVarsView.swift`:

```swift
import SwiftUI

struct EnvVarsView: View {
    @Bindable var manager: SettingsFileManager

    @State private var newKey = ""
    @State private var newValue = ""

    private var sortedKeys: [String] {
        manager.settings.env.keys.sorted()
    }

    var body: some View {
        Form {
            Section("Environment Variables") {
                if manager.settings.env.isEmpty {
                    Text("No environment variables configured")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(sortedKeys, id: \.self) { key in
                        HStack {
                            Text(key)
                                .font(.system(.body, design: .monospaced))
                                .frame(minWidth: 150, alignment: .leading)

                            EnvValueField(
                                value: manager.settings.env[key] ?? "",
                                onCommit: { newVal in
                                    manager.updateSettings { $0.env[key] = newVal }
                                }
                            )

                            Button(role: .destructive) {
                                manager.updateSettings { $0.env.removeValue(forKey: key) }
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }

                HStack {
                    TextField("KEY", text: $newKey)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .frame(minWidth: 150)
                    TextField("value", text: $newValue)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                    Button("Add") {
                        addEnvVar()
                    }
                    .disabled(newKey.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .onSubmit {
                    addEnvVar()
                }
            }
        }
        .formStyle(.grouped)
    }

    private func addEnvVar() {
        let key = newKey.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { return }
        let value = newValue
        manager.updateSettings { $0.env[key] = value }
        newKey = ""
        newValue = ""
    }
}

struct EnvValueField: View {
    @State var value: String
    var onCommit: (String) -> Void

    init(value: String, onCommit: @escaping (String) -> Void) {
        self._value = State(initialValue: value)
        self.onCommit = onCommit
    }

    var body: some View {
        TextField("Value", text: $value)
            .textFieldStyle(.roundedBorder)
            .font(.system(.body, design: .monospaced))
            .onSubmit {
                onCommit(value)
            }
    }
}
```

- [ ] **Step 2: Wire EnvVarsView into SettingsDetailView**

In `ClaudeControlPane/Sources/Views/SettingsDetailView.swift`, replace the Environment tab placeholder:

Change:
```swift
            Tab("Environment", systemImage: "terminal") {
                Text("Environment Variables (coming soon)")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
```

To:
```swift
            Tab("Environment", systemImage: "terminal") {
                EnvVarsView(manager: manager)
            }
```

- [ ] **Step 3: Build to verify**

```bash
cd ClaudeControlPane && swift build 2>&1
```

Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
git add ClaudeControlPane/Sources/Views/EnvVarsView.swift ClaudeControlPane/Sources/Views/SettingsDetailView.swift
git commit -m "feat: add environment variables view with key-value editing"
```

---

### Task 10: Update App Entry Point + Final Integration

**Files:**
- Modify: `ClaudeControlPane/Sources/App/ClaudeControlPaneApp.swift`

- [ ] **Step 1: Polish the app entry point**

Update `ClaudeControlPane/Sources/App/ClaudeControlPaneApp.swift`:

```swift
import SwiftUI

@main
struct ClaudeControlPaneApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 800, height: 600)
    }
}
```

- [ ] **Step 2: Full build**

```bash
cd ClaudeControlPane && swift build 2>&1
```

Expected: Build succeeds with no errors or warnings.

- [ ] **Step 3: Run the app to smoke-test**

```bash
cd ClaudeControlPane && swift run &
```

Expected: App window opens with sidebar showing "Global Settings" and any discovered projects. Clicking "Global Settings" shows tabs for Hooks, Permissions, Environment. The sound hook toggle should reflect the current state of `~/.claude/settings.json`.

Kill the app after verifying: `kill %1`

- [ ] **Step 4: Commit**

```bash
git add ClaudeControlPane/
git commit -m "feat: finalize app entry point and integration"
```
