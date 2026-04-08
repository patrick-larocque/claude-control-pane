# Claude Control Pane — Design Spec

> Historical note: this document describes the original narrower v1 scope for the app. It is no longer the current source of truth for product scope or architecture. Use `/README.md`, `/CLAUDE.md`, and the current source tree for up-to-date behavior.

A native macOS SwiftUI app for managing Claude Code settings visually. Replaces manual JSON editing of `settings.json` with a GUI for hooks, permissions, and environment variables.

## Scope

**In scope (v1):**
- Toggle and edit hooks (Stop sound hook as the flagship feature)
- Manage permissions (defaultMode, allow/deny/ask lists)
- Manage environment variables
- Global settings (`~/.claude/settings.json`)
- Project-level settings (`<project>/.claude/settings.json`)
- Auto-discover projects from common directories
- Manual "Add Project" for unlisted projects
- Watch for external file changes and refresh UI

**Out of scope (v1):**
- `settings.local.json` editing
- Plugin management
- Model/effort settings
- Creating new projects

## Architecture

Standard SwiftUI app (not document-based). Single window with `NavigationSplitView`.

### Layers

1. **Model** — Swift structs (`Codable`) mirroring `settings.json` schema. Preserves unknown keys via `[String: AnyCodable]` round-tripping so the app doesn't clobber fields it doesn't know about.

2. **SettingsFileManager** — One instance per settings file. Reads/writes JSON. Watches for external changes via `DispatchSource.makeFileSystemObjectSource`. Publishes changes to the store.

3. **SettingsStore** (`@Observable`) — Holds the global settings manager and a list of project settings managers. Handles project discovery and persistence of known project paths via `UserDefaults`.

4. **Views** — Sidebar + detail area with tabs.

### View Hierarchy

```
App (WindowGroup)
└── ContentView (NavigationSplitView)
    ├── Sidebar
    │   ├── "Global Settings" (always present)
    │   ├── Section: "Projects"
    │   │   ├── ProjectA
    │   │   ├── ProjectB
    │   │   └── ...
    │   └── "Add Project..." button
    └── Detail (TabView)
        ├── Tab: Hooks
        ├── Tab: Permissions
        └── Tab: Environment Variables
```

## Data Model

```
ClaudeSettings
├── permissions: PermissionsConfig
│   ├── defaultMode: String?
│   ├── allow: [String]
│   ├── deny: [String]
│   └── ask: [String]
├── hooks: [String: [HookGroup]]
│   └── HookGroup
│       └── hooks: [Hook]
│           ├── type: String ("command")
│           └── command: String
└── env: [String: String]
```

**Hook event names:** `Stop`, `PreToolUse`, `PostToolUse`, `Notification`, `SubagentStop`.

**File paths:**
- Global: `~/.claude/settings.json`
- Project: `<project-root>/.claude/settings.json`

## Key Behaviors

### Settings Read/Write
- On launch, read `~/.claude/settings.json` and all discovered project settings files.
- On any UI change, write the full settings JSON back to disk immediately.
- Preserve unknown top-level and nested keys during round-trip (the app must not delete fields like `statusLine`, `enabledPlugins`, etc. that it doesn't manage).

### File Watching
- Use `DispatchSource.makeFileSystemObjectSource` on each managed settings file.
- On external change detected, re-read the file and update the UI.
- Debounce rapid changes (100ms) to avoid thrashing.

### Project Discovery
- On launch, scan these directories (one level deep) for child directories containing `.claude/settings.json`:
  - `~/Documents`
  - `~/code`
  - `~/Developer`
  - `~/Projects`
  - `~/src`
- Also load any manually-added project paths from `UserDefaults`.
- "Add Project..." opens an `NSOpenPanel` directory picker, saves the path to `UserDefaults`.

### Hooks UI
- List all hook events. For each, show the configured hooks as rows.
- Each hook row shows the command and a toggle to enable/disable it.
- "Disable" removes the hook from the JSON (or comments-out equivalent: moves to a disabled store in UserDefaults so it can be re-enabled).
- "Add Hook" button per event to add a new command hook.
- The Stop sound hook (`afplay /System/Library/Sounds/Funk.aiff`) gets a friendly toggle at the top: "Play sound when Claude finishes".

### Permissions UI
- Dropdown for `defaultMode` (options: `default`, `bypassPermissions`, `plan`, `acceptEdits`).
- Three editable lists: Allow, Deny, Ask. Each entry is a string pattern (e.g., `Bash(git:*)`).
- Add/remove buttons for each list.

### Environment Variables UI
- Key-value table with add/remove rows.
- Inline editing for both key and value.

## Technology

- **Swift 6 / SwiftUI** — targets macOS 14 (Sonoma) or later
- **No external dependencies** — pure Apple frameworks
- **Xcode project** — standard `.xcodeproj` setup

## Error Handling

- If a settings file has invalid JSON, show an inline warning and don't overwrite. Let the user fix it externally.
- If a settings file doesn't exist yet (e.g., project has no `.claude/settings.json`), create it on first edit with only the fields being set.
- File permission errors shown as alerts.
