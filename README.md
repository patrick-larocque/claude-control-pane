# Claude Control Pane

A native macOS app for inspecting and editing Claude Code configuration without hand-editing JSON.

## What It Covers

The app now spans both machine-level and workspace-level Claude surfaces:

- Machine settings in `~/.claude/settings.json`
- Global preferences in `~/.claude.json`
- Machine agents, skills, instructions, rules, output styles, and hook scripts
- Workspace shared settings in `.claude/settings.json`
- Workspace local settings in `.claude/settings.local.json`
- Workspace shared MCP in `.mcp.json`
- Workspace local MCP stored under the project entry in `~/.claude.json`
- Workspace agents, skills, and instruction files
- Plugin inventory and diagnostics views

Within editable settings files, the app supports:

- Hooks, including extended hook payloads and tool matchers
- Permissions with allow / deny / ask lists and default mode
- Environment variables
- Advanced Claude settings such as model, language, output style, shell, effort, and structured objects like `statusLine`, `sandbox`, and `worktree`
- Raw JSON editing for the full settings file

## Current Feature Set

- Machine and workspace navigation in a single `NavigationSplitView`
- Auto-discovery of Claude workspaces from common directories
- Separate shared vs local workspace configuration surfaces
- Live file watching for settings and text-backed editors
- Lossless round-tripping of unknown JSON fields
- Validation for object-only structured editors
- Plugin cache inspection and diagnostics guidance
- Swift Package test suite covering round-trip behavior and validation logic

## Build And Test

```bash
cd ClaudeControlPane

# Run the test suite
swift test

# Build the executable
swift build

# Build a macOS app bundle
chmod +x build-app.sh
./build-app.sh
```

The app bundle is created at `ClaudeControlPane/.build/debug/Claude Control Pane.app`.

## Project Layout

```text
ClaudeControlPane/
  Sources/
    App/                  # App entry point
    Models/               # Claude settings and global-config models
    Services/             # File managers, discovery, diagnostics
    Views/                # SwiftUI feature surfaces and text editors
  Tests/                  # Round-trip and validation tests
  Package.swift           # Swift package manifest
  build-app.sh            # Convenience app-bundle builder
```

## Source Of Truth Docs

- `README.md` is the current product overview.
- `CLAUDE.md` is the current engineering orientation doc.
- `docs/superpowers/` contains historical plan/spec material from the original narrower scope and should not be treated as the current feature contract.

## License

MIT. See [LICENSE](LICENSE).
