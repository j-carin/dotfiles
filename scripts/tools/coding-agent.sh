#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-bash}"
PI_NPM_PACKAGES=(
    @mariozechner/pi-coding-agent
    @tmustier/pi-ralph-wiggum
)
PI_AGENT_PACKAGES=(
    npm:@tmustier/pi-ralph-wiggum
    npm:pi-web-access
    npm:pi-markdown-preview
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

install_pi_tools_bash() {
    if ! command -v npm >/dev/null 2>&1; then
        echo "[!] Warning: npm not found; skipping pi tool install"
        return
    fi

    echo "[*] Installing pi tools (bash nvm context)..."
    if ! npm install -g "${PI_NPM_PACKAGES[@]}"; then
        echo "[!] Warning: Failed to install pi tools via npm"
    fi
}

install_pi_tools_fish() {
    if ! fish -c 'nvm use lts >/dev/null; command -q npm'; then
        echo "[!] Warning: npm not available in fish nvm context; skipping pi tool install"
        return
    fi

    echo "[*] Installing pi tools (fish nvm context)..."
    if ! fish -c 'nvm use lts >/dev/null; npm install -g @mariozechner/pi-coding-agent @tmustier/pi-ralph-wiggum'; then
        echo "[!] Warning: Failed to install pi tools via fish npm"
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

case "$MODE" in
    fish)
        install_pi_tools_fish
        ;;
    bash)
        install_pi_tools_bash
        ;;
    *)
        echo "Usage: $0 [fish|bash]"
        exit 1
        ;;
esac

configure_pi_packages
