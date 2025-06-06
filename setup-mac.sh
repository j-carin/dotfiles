#!/usr/bin/env bash
set -euo pipefail

# Ensure Homebrew exists
if ! command -v brew >/dev/null 2>&1; then
    echo "[*] Installing Homebrew (requires Xcode Command Line Tools)"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if [[ "${AUTO_YES:-false}" == "true" ]]; then
    REPLY="y"
else
    read -p $'\nUpdate Homebrew and install core packages? [y/N] ' -r
fi
if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    brew update
    brew install git curl wget vim htop tree bat fzf ripgrep ncdu fish tmux
fi
