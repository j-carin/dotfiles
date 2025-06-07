#!/usr/bin/env bash
set -euo pipefail

if [[ "${AUTO_YES:-false}" == "true" ]]; then
    REPLY="y"
else
    read -p $'\nUpdate apt and install core packages? [y/N] ' -r
fi
if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    sudo apt-add-repository ppa:fish-shell/release-3
    sudo apt update && sudo apt -y upgrade
    sudo apt install -y git curl wget vim htop tree pkg-config
    sudo apt install -y bat fzf ripgrep ncdu fish tmux
fi

# Install magic-trace (x86_64 only)
if ! command -v magic-trace >/dev/null 2>&1; then
    if [[ "$(uname -m)" == "x86_64" ]]; then
        mkdir -p "$HOME/.local/bin"
        curl -Lo "$HOME/.local/bin/magic-trace" \
             https://github.com/janestreet/magic-trace/releases/download/v1.2.4/magic-trace
        chmod +x "$HOME/.local/bin/magic-trace"
    else
        echo "[-] magic-trace unsupported on this architecture."
    fi
fi
