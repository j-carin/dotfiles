#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
export SCRIPT_DIR            # sub-scripts rely on this

# Check for -y flag
export AUTO_YES=false
if [[ "${1:-}" == "-y" ]]; then
    export AUTO_YES=true
fi

case "$(uname -s)" in
    Linux)   bash "$SCRIPT_DIR/scripts/setup/linux.sh"  ;;
    Darwin)  bash "$SCRIPT_DIR/scripts/setup/mac.sh"    ;;
    *)       echo "Unsupported OS"; exit 1      ;;
esac

# -------- common steps --------
# Initialize git submodules (for secrets)
if [[ -d ".git" ]]; then
    echo "[*] Initializing git submodules..."
    git submodule update --init --recursive
fi

# Optional: Enable passwordless sudo
if [[ "$AUTO_YES" == "true" ]]; then
    REPLY="y"
else
    read -p $'\nEnable passwordless sudo? [y/N] ' -r
fi
if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    USERNAME=$(whoami)
    SUDOERS_LINE="$USERNAME ALL=(ALL) NOPASSWD: ALL"
    echo "[*] Configuring passwordless sudo for $USERNAME..."
    echo "$SUDOERS_LINE" | sudo tee /etc/sudoers.d/nopasswd-$USERNAME > /dev/null
    if [ $? -eq 0 ]; then
        echo "[+] Passwordless sudo configured successfully"
    else
        echo "[!] Failed to configure passwordless sudo"
    fi
fi

# Install Vim configuration
if [[ ! -d "$HOME/.vim_runtime" ]]; then
    git clone --depth=1 https://github.com/amix/vimrc.git "$HOME/.vim_runtime"
    sh "$HOME/.vim_runtime/install_awesome_vimrc.sh"
fi

# Install Rust
if ! command -v rustc >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# Install uv
if ! command -v uv >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Install zoxide
if ! command -v zoxide >/dev/null 2>&1; then
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    # Add to .bashrc if not already present
    if ! grep -q "zoxide init bash" "$HOME/.bashrc" 2>/dev/null; then
        echo 'eval "$(zoxide init bash --cmd cd)"' >> "$HOME/.bashrc"
        echo 'export _ZO_DOCTOR=0'                 >> "$HOME/.bashrc"
    fi
fi

# Optional Rust CLI set (slow, so ask)
if [[ "$AUTO_YES" == "true" ]]; then
    REPLY="y"
else
    read -p $'\nInstall cargo packages? [y/N] ' -r
fi
if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    bash "$SCRIPT_DIR/scripts/tools/cargo.sh"
fi

# Create Claude configuration directory and settings
mkdir -p "$HOME/.claude"

bash "$SCRIPT_DIR/ln.sh"

# Offer to switch default shell to fish
if command -v fish >/dev/null 2>&1; then
    if [[ "$AUTO_YES" == "true" ]]; then
        REPLY="y"
    else
        read -p $'\nChange default shell to fish? [y/N] ' -r
    fi
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        FISH_PATH="$(command -v fish)"
        if ! grep -qx "$FISH_PATH" /etc/shells; then
            echo "[*] Adding $FISH_PATH to /etc/shells (sudo)"
            echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
        fi
        sudo usermod -s "$FISH_PATH" "$USER" && echo "[+] Default shell changed."

        # Optional AI tools installation (requires fish)
        if [[ "$AUTO_YES" == "true" ]]; then
            AI_REPLY="y"
        else
            read -p $'\nInstall AI tools (Claude Code CLI and OpenAI Codex)? [y/N] ' -r AI_REPLY
        fi
        if [[ "$AI_REPLY" =~ ^[Yy]$ ]]; then
            echo "[*] AI tools will be installed in fish shell..."
            # Use a proper fish wrapper instead of exec to maintain script context
            fish_wrapper_script=$(mktemp)
            cat > "$fish_wrapper_script" << 'EOF'
#!/usr/bin/env fish
source "$argv[1]"
EOF
            chmod +x "$fish_wrapper_script"
            "$fish_wrapper_script" "$SCRIPT_DIR/scripts/tools/ai.sh"
            rm "$fish_wrapper_script"
        else
            exec fish
        fi
    fi
fi
