#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

mkdir -p "$HOME/.config/fish"
mkdir -p "$HOME/.config/fish/functions"
mkdir -p "$HOME/.config/ghostty"
mkdir -p "$HOME/.pi/agent"

# dotfiles
ln -sf "$SCRIPT_DIR/config/gitconfig"        "$HOME/.gitconfig"
ln -sf "$SCRIPT_DIR/config/gitignore"        "$HOME/.gitignore"
ln -sf "$SCRIPT_DIR/config/bash_aliases"     "$HOME/.bash_aliases"

# terminal
ln -sf "$SCRIPT_DIR/config/tmux.conf"        "$HOME/.tmux.conf"
ln -sf "$SCRIPT_DIR/config/ghostty/config"   "$HOME/.config/ghostty/config"

# pi
ln -sf "$SCRIPT_DIR/config/pi/agent/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"

# fish
ln -sf "$SCRIPT_DIR/config/fish/config.fish" "$HOME/.config/fish/config.fish"
for func in "$SCRIPT_DIR/config/fish/functions"/*.fish; do
    if [ -f "$func" ]; then
        ln -sf "$func" "$HOME/.config/fish/functions/$(basename "$func")"
    fi
done

# claude code skills
mkdir -p "$HOME/.claude/skills"
for skill in "$SCRIPT_DIR/skills"/*/; do
    if [ -d "$skill" ]; then
        ln -sfn "$skill" "$HOME/.claude/skills/$(basename "$skill")"
    fi
done

# pi skills
mkdir -p "$HOME/.pi/agent/skills"
for skill in "$SCRIPT_DIR/skills"/*/; do
    if [ -d "$skill" ]; then
        ln -sfn "$skill" "$HOME/.pi/agent/skills/$(basename "$skill")"
    fi
done

# gdrive
if [ -d "$SCRIPT_DIR/secrets/gdrive3" ]; then
    ln -sfn "$SCRIPT_DIR/secrets/gdrive3" "$HOME/.config/gdrive3"
fi
