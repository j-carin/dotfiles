#!/usr/bin/env fish

echo "[*] Installing Claude Code CLI with fish and nvm.fish..."

# Install Fisher plugin manager if not present
if not functions -q fisher
    echo "[*] Installing Fisher plugin manager..."
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
end

# Install nvm.fish if not present
if not functions -q nvm
    echo "[*] Installing nvm.fish..."
    fisher install jorgebucaran/nvm.fish
end

# Install Node.js 22 if not present
if not nvm list | grep -q v22
    echo "[*] Installing Node.js 22..."
    nvm install 22
end

# Set Node.js 22 as default
echo "[*] Setting Node.js 22 as default..."
nvm use 22
echo "22" > ~/.nvmrc

# Install Claude Code CLI globally
echo "[*] Installing @anthropic-ai/claude-code..."
npm install -g @anthropic-ai/claude-code

# Verify installation
echo "[*] Verifying installation..."
if command -q claude
    echo "[+] Claude Code CLI installed successfully!"
    echo "Try: claude --help"
    echo ""
    echo "Node.js version: "(node --version)
    echo "npm global prefix: "(npm config get prefix)
else
    echo "[-] Installation verification failed."
    echo "Current PATH: $PATH"
    echo "npm global prefix: "(npm config get prefix)
end