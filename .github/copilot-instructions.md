# ClaudeControlPane – Copilot Workspace Instructions

See `CLAUDE.md` for full project context, architecture, conventions, and worktree workflow.

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

## Worktrees
New feature branches should be developed in isolated worktrees (sibling folders), not directly on `main`.

```bash
# From repo root: ~/Documents/claude-control-pane
./scripts/new-worktree.sh <branch-name>   # create sandbox
./scripts/remove-worktree.sh <branch-name> # clean up
git worktree list                          # see all active worktrees
```

Each worktree automatically inherits `.claude/settings.json` and `.vscode/settings.json` (both tracked), so Claude Code and Copilot work immediately with no setup.

## Agent Permissions
- **Copilot** — auto-approves read, search, write, and terminal tools (see `.vscode/settings.json`)
- **Claude Code** — pre-approved bash commands in `.claude/settings.json`: `git *`, `swift *`, `chmod *`, `cat *`, `ls *`, `find *`, `mkdir *`, `cp *`, `mv *`, `rm *`, `echo *`, `open *`, `grep *`, `sed *`, `awk *`
