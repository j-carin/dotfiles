#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-bash}"
PI_PACKAGES=(
    @mariozechner/pi-coding-agent
    @tmustier/pi-ralph-wiggum
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
    if ! npm install -g "${PI_PACKAGES[@]}"; then
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
