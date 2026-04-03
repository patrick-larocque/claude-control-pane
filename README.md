# Claude Control Pane

A native macOS app for managing [Claude Code](https://docs.anthropic.com/en/docs/claude-code) settings visually -- no more hand-editing JSON.

## What it does

Claude Code stores its configuration in `settings.json` files. This app gives you a GUI to manage:

- **Hooks** -- event-triggered shell commands (e.g. play a sound when Claude finishes)
- **Permissions** -- control which tools Claude can use, with allow/deny/ask lists
- **Environment variables** -- key-value pairs passed to Claude Code sessions

It supports both global settings (`~/.claude/settings.json`) and per-project settings, with automatic project discovery from common directories.

## Features

- Sidebar with global + per-project settings
- Live file watching -- picks up external edits automatically
- Preserves unknown JSON fields (won't clobber settings it doesn't understand)
- Quick toggle for common hooks (e.g. "Play sound on finish")
- No external dependencies -- pure Swift + SwiftUI

## Requirements

- macOS 14 (Sonoma) or later
- Swift 6 toolchain

## Building

```bash
cd ClaudeControlPane

# Build the executable
swift build

# Or build a proper .app bundle
chmod +x build-app.sh
./build-app.sh
```

The app bundle is created at `.build/debug/Claude Control Pane.app`.

## Project structure

```
ClaudeControlPane/
  Sources/
    App/                  # App entry point
    Models/               # Settings data structures (Codable JSON models)
    Services/             # File I/O, file watching, project discovery
    Views/                # SwiftUI views (sidebar, hooks, permissions, env vars)
  Package.swift           # Swift package manifest
  build-app.sh            # macOS app bundle builder
```

## How it works

1. **SettingsFileManager** reads/writes JSON and watches the file system for external changes (debounced, using `DispatchSource`)
2. **SettingsStore** holds global and per-project managers, discovers projects on launch
3. **SwiftUI views** bind reactively to the store -- edits save immediately

Unknown JSON fields are preserved via a generic `AnyCodableValue` wrapper, so the app is forward-compatible with new Claude Code settings.

## License

MIT -- see [LICENSE](LICENSE).
