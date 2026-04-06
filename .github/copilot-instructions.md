# ClaudeControlPane – Copilot Workspace Instructions

See `ClaudeControlPane/CLAUDE.md` for full project context, architecture, and conventions.

## Overview
Native macOS SwiftUI app (macOS 14+, Swift 6) for managing Claude Code `settings.json` files via a GUI. Uses SPM, `@Observable`, strict concurrency.

## Key Rules
- Swift 6 strict concurrency — all models `Sendable`, services `@MainActor`
- No Combine — use `async`/`await` and `@Observable`
- No save button — every UI edit writes to disk immediately
- No force unwrapping — use optional chaining/nil coalescing
- 4-space indentation

## Build
```bash
cd ClaudeControlPane && swift build
# or open ClaudeControlPane/Package.swift in Xcode
```
