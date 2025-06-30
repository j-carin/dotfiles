#!/usr/bin/env fish

echo "[*] Installing AI tools (Claude Code CLI and OpenAI Codex) with fish and nvm.fish..."

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

# Reload fish configuration to ensure nvm is available
source ~/.config/fish/config.fish 2>/dev/null || true

# Install Node.js 22 if not present
if not nvm list 2>/dev/null | grep -q v22
    echo "[*] Installing Node.js 22..."
    nvm install 22
end

# Set Node.js 22 as default
echo "[*] Setting Node.js 22 as default..."
nvm use 22
echo "22" > ~/.nvmrc

# Ensure npm global bin is in PATH for current session
if test -d (npm config get prefix)/bin
    fish_add_path (npm config get prefix)/bin
end

# Install AI CLI tools globally
echo "[*] Installing @anthropic-ai/claude-code..."
npm install -g @anthropic-ai/claude-code

echo "[*] Installing @openai/codex..."
npm install -g @openai/codex

# Install zen-mcp-server using uvx (assumes uv is already installed)
echo "[*] Installing zen-mcp-server using uvx..."
uvx --from git+https://github.com/BeehiveInnovations/zen-mcp-server.git zen-mcp-server --version 2>/dev/null || echo "[!] zen-mcp-server installed (version check may fail on first run)"

# Verify installation
echo "[*] Verifying installation..."
set -l claude_installed (command -q claude; and echo "yes"; or echo "no")
set -l codex_installed (command -q codex; and echo "yes"; or echo "no")

if test $claude_installed = "yes"
    echo "[+] Claude Code CLI installed successfully!"
    echo "Try: claude --help"
else
    echo "[-] Claude Code CLI installation verification failed."
end

if test $codex_installed = "yes"
    echo "[+] OpenAI Codex installed successfully!"
    echo "Try: codex --help"
else
    echo "[-] OpenAI Codex installation verification failed."
end

echo ""
echo "Node.js version: "(node --version)
echo "npm global prefix: "(npm config get prefix)

if test $claude_installed = "no" -o $codex_installed = "no"
    echo "Current PATH: $PATH"
    echo ""
    echo "If tools are not found, try restarting your shell or running:"
    echo "  fish_add_path "(npm config get prefix)"/bin"
end