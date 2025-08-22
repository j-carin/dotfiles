#!/usr/bin/env bash

# Check for dotfiles updates in background

DOTFILES_DIR="$(dirname "$(dirname "$(dirname "$0")")")"

# Skip if not a git repo or no remote
cd "$DOTFILES_DIR" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0
git remote get-url origin >/dev/null 2>&1 || exit 0

# Check for updates
if git fetch origin --quiet 2>/dev/null; then
    behind_count=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo "0")
    
    if [[ "$behind_count" -gt 0 ]]; then
        mkdir -p ~/.cache
        echo "$behind_count" > ~/.cache/dotfiles-updates-available
        echo "dotfiles: Updates available ($behind_count commits). Type 'dotfiles_pull' to update."
    fi
fi