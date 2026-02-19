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
# Initialize git submodules (for secrets) - optional, continue if it fails
if [[ -d ".git" ]]; then
    echo "[*] Initializing git submodules..."
    if ! git submodule update --init --recursive; then
        echo "[!] Warning: Failed to initialize git submodules (secrets). Continuing anyway..."
    fi
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

# Ask once whether to use fish as default shell (fish-first setup flow)
USE_FISH=false
if command -v fish >/dev/null 2>&1; then
    if [[ "$AUTO_YES" == "true" ]]; then
        REPLY="y"
    else
        read -p $'\nChange default shell to fish? [y/N] ' -r
    fi
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        USE_FISH=true
    fi
else
    echo "fish not installed."
fi

# Install Node.js LTS + coding-agent tools
ensure_node_lts_bash() {
    export NVM_DIR="$HOME/.nvm"
    if [[ ! -d "$NVM_DIR" ]]; then
        echo "[*] Installing nvm..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    fi

    # nvm scripts are not consistently nounset-safe; setup.sh runs with `set -u`.
    local had_u=0
    [[ $- == *u* ]] && had_u=1
    set +u

    # shellcheck source=/dev/null
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    if ! command -v nvm >/dev/null 2>&1; then
        echo "[!] Warning: nvm failed to load in bash context"
        [[ $had_u -eq 1 ]] && set -u
        return 1
    fi

    echo "[*] Ensuring Node.js LTS is installed (bash nvm context)..."
    nvm install --lts
    nvm alias default 'lts/*' >/dev/null
    nvm use --lts >/dev/null

    [[ $had_u -eq 1 ]] && set -u
}

if [[ "$USE_FISH" == "true" ]]; then
    echo "[*] Installing fisher and nvm.fish for fish..."
    if ! fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'; then
        echo "[!] Warning: Failed to install fisher"
    fi
    if ! fish -c 'fisher install jorgebucaran/nvm.fish'; then
        echo "[!] Warning: Failed to install nvm.fish"
    fi

    echo "[*] Setting fish nvm default to LTS..."
    if ! fish -c 'set -U nvm_default_version lts; nvm install lts; nvm use lts >/dev/null'; then
        echo "[!] Warning: Failed to configure fish nvm LTS"
    fi
fi

if ensure_node_lts_bash; then
    bash "$SCRIPT_DIR/scripts/tools/coding-agent.sh" bash
else
    echo "[!] Warning: Skipping coding-agent install because Node.js LTS setup failed"
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

bash "$SCRIPT_DIR/ln.sh"

# Compile terminfo for xterm-ghostty
echo "[*] Compiling terminfo for xterm-ghostty..."
tic -x -o "$HOME/.terminfo" "$SCRIPT_DIR/config/terminfo/xterm-ghostty.src"

# Apply default shell change if fish was selected earlier
if [[ "$USE_FISH" == "true" ]]; then
    FISH_PATH="$(command -v fish)"
    if ! grep -qx "$FISH_PATH" /etc/shells; then
        echo "[*] Adding $FISH_PATH to /etc/shells (sudo)"
        echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
    fi
    if [[ "$(uname -s)" == "Darwin" ]]; then
        chsh -s "$FISH_PATH" && echo "[+] Default shell changed."
    else
        sudo usermod -s "$FISH_PATH" "$USER" && echo "[+] Default shell changed."
    fi

    echo "[+] Setup completed successfully."
    exec fish
fi

echo "[+] Setup completed successfully."
