#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

mkdir -p "$HOME/.config/fish"
mkdir -p "$HOME/.config/fish/functions"
mkdir -p "$HOME/.config/ghostty"
mkdir -p "$HOME/.codex"
mkdir -p "$HOME/.claude"
mkdir -p "$HOME/.opencode"

# dotfiles
ln -sf "$SCRIPT_DIR/config/gitconfig"        "$HOME/.gitconfig"
ln -sf "$SCRIPT_DIR/config/gitignore"        "$HOME/.gitignore"
ln -sf "$SCRIPT_DIR/config/bash_aliases"     "$HOME/.bash_aliases"

# terminal
ln -sf "$SCRIPT_DIR/config/tmux.conf"        "$HOME/.tmux.conf"
ln -sf "$SCRIPT_DIR/config/ghostty/config"   "$HOME/.config/ghostty/config"

# codex
ln -sf "$SCRIPT_DIR/config/codex/config.json" "$HOME/.codex/config.json"

# opencode
ln -sf "$SCRIPT_DIR/config/opencode/opencode.json" "$HOME/.opencode/opencode.json"
ln -sfn "$SCRIPT_DIR/skills" "$HOME/.opencode/skill"

# claude code
for claude_file in "$SCRIPT_DIR/config/claude"/*; do
    if [ -f "$claude_file" ]; then
        ln -sf "$claude_file" "$HOME/.claude/$(basename "$claude_file")"
    fi
done

# fish
ln -sf "$SCRIPT_DIR/config/fish/config.fish" "$HOME/.config/fish/config.fish"
for func in "$SCRIPT_DIR/config/fish/functions"/*.fish; do
    if [ -f "$func" ]; then
        ln -sf "$func" "$HOME/.config/fish/functions/$(basename "$func")"
    fi
done

# gdrive
if [ -d "$SCRIPT_DIR/secrets/gdrive3" ]; then
    ln -sfn "$SCRIPT_DIR/secrets/gdrive3" "$HOME/.config/gdrive3"
fi
