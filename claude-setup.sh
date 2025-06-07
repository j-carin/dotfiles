#!/usr/bin/env bash
set -euo pipefail

echo "[*] Installing Claude Code CLI..."

# Install Node.js via system package manager if not present
if ! command -v node >/dev/null 2>&1; then
    echo "[*] Installing Node.js..."
    case "$(uname -s)" in
        Linux)   
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt-get install -y nodejs
            ;;
        Darwin)  
            if command -v brew >/dev/null 2>&1; then
                brew install node
            else
                echo "[-] Homebrew not found. Please install Node.js manually."
                exit 1
            fi
            ;;
    esac
fi

# Install Claude Code CLI globally
echo "[*] Installing @anthropic-ai/claude-code..."
npm install -g @anthropic-ai/claude-code

# Verify installation
echo "[*] Verifying installation..."
if command -v claude >/dev/null 2>&1; then
    echo "[+] Claude Code CLI installed successfully!"
    echo "Try: claude --help"
else
    echo "[-] Installation failed. You may need to add npm global bin to your PATH."
    echo "Add this to your shell config: export PATH=\"\$(npm config get prefix)/bin:\$PATH\""
fi