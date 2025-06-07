#!/usr/bin/env bash
set -euo pipefail

echo "[*] Setting up Claude Code CLI..."

# Check if we're using fish shell, if not warn user
if [[ "${SHELL##*/}" != "fish" ]]; then
    echo "[-] Warning: This script is optimized for fish shell. You may need manual configuration for other shells."
fi

# Install Fisher (plugin manager for fish) if not already installed
if ! fish -c 'functions -q fisher' 2>/dev/null; then
    echo "[*] Installing Fisher (fish plugin manager)..."
    fish -c 'curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher'
fi

# Install nvm.fish if not already installed
if ! fish -c 'functions -q nvm' 2>/dev/null; then
    echo "[*] Installing nvm.fish..."
    fish -c 'fisher install jorgebucaran/nvm.fish'
    echo "[*] Restarting fish to load nvm..."
    exec fish -c "source ~/.config/fish/config.fish"
fi

# Install Node.js 22 and set as default
echo "[*] Installing Node.js 22..."
fish -c 'nvm install 22 && nvm use 22'

# Create global .nvmrc
echo "[*] Setting Node.js 22 as default version..."
echo "22" > "$HOME/.nvmrc"

# Update fish config to auto-activate Node and add npm global bin to PATH
FISH_CONFIG="$HOME/.config/fish/config.fish"
if ! grep -q "nvm use --silent" "$FISH_CONFIG" 2>/dev/null; then
    echo "[*] Updating fish config for auto Node activation..."
    echo "" >> "$FISH_CONFIG"
    echo "# Auto-activate Node.js version from .nvmrc" >> "$FISH_CONFIG"
    echo "nvm use --silent" >> "$FISH_CONFIG"
fi

if ! grep -q "\$HOME/.npm/bin" "$FISH_CONFIG" 2>/dev/null; then
    echo "[*] Adding npm global bin to PATH..."
    echo "" >> "$FISH_CONFIG"
    echo "# Add npm global binaries to PATH" >> "$FISH_CONFIG"
    echo 'if not contains "$HOME/.npm/bin" $PATH' >> "$FISH_CONFIG"
    echo '    set -gx PATH "$HOME/.npm/bin" $PATH' >> "$FISH_CONFIG"
    echo 'end' >> "$FISH_CONFIG"
fi

# Source the updated config
fish -c "source ~/.config/fish/config.fish"

# Install Claude Code CLI globally
echo "[*] Installing Claude Code CLI..."
fish -c 'npm install -g @anthropic-ai/claude-code'

# Verify installation
echo "[*] Verifying installation..."
if fish -c 'claude --help' >/dev/null 2>&1; then
    echo "[+] Claude Code CLI installed successfully!"
    echo ""
    echo "Setup complete! You can now use 'claude' in any new terminal."
    echo "Try: claude --help"
else
    echo "[-] Installation may have failed. Please check the output above."
    exit 1
fi