#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <branch-name>"
  exit 1
fi

BRANCH="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

git worktree add "../claude-control-pane-$BRANCH" -b "$BRANCH"

echo ""
echo "✅ Worktree created at: $(cd .. && pwd)/claude-control-pane-$BRANCH"
echo "   Open with: code \"../claude-control-pane-$BRANCH\""
