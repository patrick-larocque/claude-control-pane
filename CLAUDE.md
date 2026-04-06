# CLAUDE.md - ClaudeControlPane

## What This Project Is

A native macOS SwiftUI app (macOS 14+) that provides a GUI for managing Claude Code `settings.json` files -- both the global config (`~/.claude/settings.json`) and per-project configs (`<project>/.claude/settings.json`). Eliminates the need to hand-edit JSON for permissions, hooks, and environment variables.

## Project Structure

```
ClaudeControlPane/
├── Package.swift                          # SPM executable target, Swift 6, macOS 14+
├── build-app.sh                           # CLI build script -> .app bundle
└── Sources/
    ├── App/
    │   └── ClaudeControlPaneApp.swift     # @main entry point, WindowGroup
    ├── Models/
    │   ├── ClaudeSettings.swift           # Root model (permissions, hooks, env, extraFields)
    │   ├── PermissionsConfig.swift        # defaultMode, allow/deny/ask arrays
    │   ├── HookConfig.swift               # Hook + HookGroup structs
    │   └── AnyCodableValue.swift          # Type-safe Any wrapper for JSON round-tripping
    ├── Services/
    │   ├── SettingsFileManager.swift       # Load/save/watch a single settings.json file
    │   ├── SettingsStore.swift             # Manages global + all project managers
    │   └── ProjectDiscovery.swift          # Scans ~/Documents, ~/code, etc. for projects
    └── Views/
        ├── ContentView.swift              # NavigationSplitView (sidebar + detail)
        ├── SidebarView.swift              # Global settings + project list + discovered + add/remove
        ├── SettingsDetailView.swift        # TabView (Hooks, Permissions, Environment) - editable
        ├── ReadOnlySettingsDetailView.swift # Read-only detail view for discovered projects
        ├── PermissionsView.swift           # Permission mode picker + allow/deny/ask editors
        ├── HooksView.swift                # Hook event editors + quick-settings toggles
        └── EnvVarsView.swift              # Key-value environment variable editor
```

## Architecture

**Model / Service / View** layers with `@Observable` (Observation framework, not Combine).

- **Models** are plain `Codable`/`Sendable` structs. `ClaudeSettings` uses manual `JSONSerialization`-based encode/decode to preserve unknown JSON fields round-trip via `AnyCodableValue`.
- **Services** use `@Observable @MainActor` classes. `SettingsFileManager` owns one file: loads, saves, and watches it via GCD `DispatchSource` with debounce. `SettingsStore` aggregates global + managed project managers + lightweight discovered projects.
- **Views** are standard SwiftUI. All mutations go through `manager.updateSettings { ... }` which mutates in-place and immediately persists to disk (no manual save step). Discovered (unmanaged) projects use a separate read-only view.

## Key Design Decisions

- **No Combine** -- uses Swift concurrency (`async`/`await`, `Task`) and `@Observable` macro.
- **Immediate persistence** -- every UI edit writes to disk instantly. No save button.
- **Live file watching** -- external edits to `settings.json` (from CLI, other editors) are detected via `DispatchSource` and reflected in the UI with 100ms debounce.
- **Lossless round-tripping** -- unknown JSON keys are preserved in `extraFields` so the app never drops config it doesn't understand.
- **Swift 6 strict concurrency** -- all models are `Sendable`, services are `@MainActor`.
- **Discovered vs Managed projects** -- auto-discovered projects (from `ProjectDiscovery`) appear in a "Discovered" sidebar section as lightweight `DiscoveredProject` structs with no file watchers. Only explicitly added (promoted/manual) projects get a `SettingsFileManager` with file descriptors and GCD watchers. This keeps resource usage minimal.
- **Read-only preview** -- discovered projects can be clicked to view their settings without adding them. A separate `ReadOnlySettingsDetailView` loads settings via a one-shot `ClaudeSettings.loadFromFile()` call (no watcher). Promoting a project via the [+] button moves it to managed with full editing.

## Building

### Xcode
Open `ClaudeControlPane/Package.swift` in Xcode, build and run (Cmd+R).

### Command Line
```bash
cd ClaudeControlPane
chmod +x build-app.sh
./build-app.sh
open .build/debug/"Claude Control Pane.app"
```

## Code Style

- **Naming**: PascalCase for types, camelCase for properties/methods
- **State**: `@State private var` for local SwiftUI state, `@Bindable var` for observable service references
- **Indentation**: 4 spaces
- **Imports**: Minimal -- `SwiftUI`, `Foundation`, `AppKit`, `Observation` only as needed
- **No force unwrapping** -- use optional chaining and nil coalescing
- **Architecture**: Prefer `@Observable` over `ObservableObject`/`@Published`. Avoid Combine.

## Common Tasks

### Adding a new settings section
1. Add the model fields to `ClaudeSettings.swift` (update `decode`/`encode` and `knownKeys`)
2. Create a new view in `Sources/Views/`
3. Add a tab in `SettingsDetailView.swift`

### Adding a new hook event
Add the event name string to `ClaudeSettings.knownHookEvents` -- the hooks UI auto-generates sections from this list.

### Adding new project scan directories
Add directory names to `ProjectDiscovery.scanDirectories`. Discovery is recursive up to `maxDepth` (currently 4), skipping hidden dirs, `node_modules`, and `.build`.

### Project discovery and promotion flow
- `ProjectDiscovery.discoverProjects()` recursively scans scan directories for `.claude/settings.json`.
- `SettingsStore.loadProjects()` partitions results: UserDefaults paths -> `projectManagers` (managed), remainder -> `discoveredProjects` (lightweight).
- `SidebarItem` enum has three cases: `.global`, `.project(String)`, `.discovered(String)`.
- `SettingsStore.promoteDiscoveredProject(_:)` saves to UserDefaults, creates a `SettingsFileManager`, and moves the project from discovered to managed.
- `SettingsStore.addProject()` (manual via NSOpenPanel) also removes from `discoveredProjects` if the path matches.

## Testing Notes

- No test target currently exists. Validate changes by building (`Cmd+R` or `swift build`).
- Use `XcodeRefreshCodeIssuesInFile` for quick compiler diagnostics without a full build.
- The app reads/writes real `settings.json` files, so test with care on your own machine.
- To test project discovery, create a test project: `mkdir -p ~/Documents/test-project/.claude && echo '{}' > ~/Documents/test-project/.claude/settings.json`
- Clean up test projects after: `rm -rf ~/Documents/test-project`
