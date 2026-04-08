# CLAUDE.md - ClaudeControlPane

## What This Repo Is

Claude Control Pane is a native macOS SwiftUI app for browsing and editing Claude Code configuration across machine-wide and workspace-specific surfaces. It is no longer limited to just hooks, permissions, and environment variables in `settings.json`.

## Current Product Surfaces

- Machine settings: `~/.claude/settings.json`
- Machine global preferences: `~/.claude.json`
- Machine agents: `~/.claude/agents`
- Machine skills: `~/.claude/skills`
- Machine instructions, rules, output styles, and hook scripts
- Plugin inventory cached under `~/.claude/plugins`
- Diagnostics for shell PATH and Claude CLI environment guidance
- Workspace shared settings: `.claude/settings.json`
- Workspace local settings: `.claude/settings.local.json`
- Workspace shared MCP: `.mcp.json`
- Workspace local MCP stored in `~/.claude.json`
- Workspace agents, skills, and instruction files
- Read-only previews for discovered but unmanaged projects

## Repo Structure

```text
claude-control-pane/
├── .gitignore
├── README.md
├── CLAUDE.md
├── docs/
│   └── superpowers/                  # Historical plan/spec artifacts
├── scripts/
│   ├── new-worktree.sh
│   └── remove-worktree.sh
└── ClaudeControlPane/
    ├── Package.swift
    ├── build-app.sh
    ├── Sources/
    │   ├── App/
    │   ├── Models/
    │   ├── Services/
    │   └── Views/
    └── Tests/
```

## Architecture

The app is a Swift Package with one executable target and one test target.

- Models
  `ClaudeSettings` and `ClaudeGlobalConfig` own JSON decoding/encoding for Claude settings surfaces.
  `AnyCodableValue` preserves unknown JSON and supports structured object editing.
  `Hook` and `HookGroup` model Claude hook handlers, including extended payload shapes.

- Services
  `SettingsFileManager`, `GlobalConfigFileManager`, and `TextFileManager` load, save, validate, and watch files with `DispatchSource`.
  `SettingsStore` aggregates machine-level managers plus managed/discovered workspaces.
  `ProjectDiscovery` scans common home-directory roots for Claude workspaces.
  `DiagnosticsService` derives environment checks and CLI guidance from current settings plus shell state.

- Views
  `ContentView` and `SidebarView` define the top-level navigation.
  `SettingsDetailView` exposes editable tabs for hooks, permissions, environment, advanced settings, and raw JSON.
  Additional feature views cover global preferences, MCP, instructions, file/directory editors, diagnostics, and plugin inventory.

## Key Behavioral Notes

- Standard settings tabs persist immediately through `manager.updateSettings { ... }`.
- Text-backed editors use explicit Save/Reload actions and live file watching.
- Unknown top-level and nested JSON is preserved on round-trip.
- Object-only editors reject non-object JSON and split empty-input handling by surface:
  empty advanced objects clear the field; empty MCP maps normalize to `{}`.
- Project-scoped panes with path-derived local state are keyed by workspace path to avoid stale content when switching projects.
- Discovered projects stay lightweight until promoted; only managed projects get active file managers and watchers.

## Feature Map By Layer

- `Sources/Models`
  Claude settings schema, global config schema, permissions, hooks, dynamic JSON values

- `Sources/Services`
  Settings/global-config file I/O, text file editing, discovery, diagnostics

- `Sources/Views`
  Machine/workspace navigation, editable settings tabs, MCP editors, instructions editors, diagnostics, plugin inventory

- `Tests`
  Round-trip coverage for advanced settings and hooks, global-config MCP behavior, diagnostics checks, and object-editor validation

## Build And Test

```bash
cd ClaudeControlPane
swift test
swift build
./build-app.sh
```

## Working Conventions

- Prefer `@Observable` over Combine-based patterns.
- Keep JSON round-tripping lossless when adding new fields.
- Use `rg` for search and `swift test` as the default verification pass.
- Avoid treating `docs/superpowers/` as the current contract unless you first update it to match the code.

## Historical Docs

The files under `docs/superpowers/` describe the original, much narrower implementation scope. They are useful as historical context, but they are not the current source of truth. Use `README.md`, `CLAUDE.md`, and the actual source tree for current behavior.
