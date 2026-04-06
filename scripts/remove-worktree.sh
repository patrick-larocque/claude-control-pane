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

git worktree remove "../claude-control-pane-$BRANCH"
echo "✅ Worktree removed: ../claude-control-pane-$BRANCH"

read -p "Also delete branch '$BRANCH'? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
  git branch -d "$BRANCH"
  echo "✅ Branch '$BRANCH' deleted."
fi
