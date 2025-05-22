#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

mkdir -p "$HOME/.config/fish"
mkdir -p "$HOME/.config/ghostty"

# Link dotfiles
ln -sf "$SCRIPT_DIR/gitconfig"               "$HOME/.gitconfig"
ln -sf "$SCRIPT_DIR/gitignore"               "$HOME/.gitignore"
ln -sf "$SCRIPT_DIR/bash_aliases"            "$HOME/.bash_aliases"

ln -sf "$SCRIPT_DIR/config/fish/config.fish" "$HOME/.config/fish/config.fish"
ln -sf "$SCRIPT_DIR/config/tmux.conf"        "$HOME/.tmux.conf"
ln -sf "$SCRIPT_DIR/config/ghostty/config"   "$HOME/.config/ghostty/config"
