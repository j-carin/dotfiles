#!/usr/bin/env bash
set -euo pipefail

PI_NPM_PACKAGES=(
    @mariozechner/pi-coding-agent
    @tmustier/pi-ralph-wiggum
    @openai/codex
)
PI_AGENT_PACKAGES=(
    npm:@tmustier/pi-ralph-wiggum
    npm:pi-codex-web-search
)

install_claude_code() {
    if command -v claude >/dev/null 2>&1; then
        echo "[*] Claude Code already installed."
        return
    fi

    echo "[*] Installing Claude Code..."
    if ! curl -fsSL https://claude.ai/install.sh | bash; then
        echo "[!] Warning: Failed to install Claude Code"
    fi
}

install_pi_tools() {
    if ! command -v npm >/dev/null 2>&1; then
        echo "[!] Warning: npm not found; skipping pi tool install"
        return
    fi

    echo "[*] Installing pi tools and Codex CLI..."
    if ! npm install -g "${PI_NPM_PACKAGES[@]}"; then
        echo "[!] Warning: Failed to install pi tools via npm"
    fi
}

configure_pi_packages() {
    if ! command -v pi >/dev/null 2>&1; then
        echo "[!] Warning: pi command not found; skipping pi package configuration"
        return
    fi

    echo "[*] Installing pi packages..."
    for package in "${PI_AGENT_PACKAGES[@]}"; do
        if ! pi install "$package"; then
            echo "[!] Warning: Failed to install $package"
        fi
    done

}

install_claude_code
install_pi_tools
configure_pi_packages
