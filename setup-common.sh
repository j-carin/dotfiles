#!/usr/bin/env bash
# Common utilities and shared functionality for setup scripts

# Common package lists
CORE_PACKAGES=(git curl wget vim htop tree bat fzf ripgrep ncdu fish tmux gh)
LINUX_SPECIFIC=(pkg-config libssl-dev)

# Shared prompt function
prompt_user() {
    local message="$1"
    if [[ "${AUTO_YES:-false}" == "true" ]]; then
        REPLY="y"
    else
        read -p "$message" -r
    fi
}

# Package manager abstraction
install_packages() {
    local packages=("$@")
    
    case "$(uname -s)" in
        Linux)
            sudo apt-add-repository -y ppa:fish-shell/release-3
            sudo apt update && sudo apt -y upgrade
            sudo apt install -y "${packages[@]}"
            ;;
        Darwin)
            brew update
            brew install "${packages[@]}"
            ;;
        *)
            echo "Unsupported OS for package installation"
            return 1
            ;;
    esac
}

# Install platform-specific tools
install_platform_specific() {
    case "$(uname -s)" in
        Linux)
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
            
            # Create bat symlink (Ubuntu installs as batcat)
            if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
                echo "[*] Creating bat symlink for batcat..."
                sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
            fi
            ;;
        Darwin)
            # macOS-specific tools can be added here
            echo "[*] No macOS-specific tools to install"
            ;;
    esac
}

# Ensure Homebrew exists (macOS only)
ensure_homebrew() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        if ! command -v brew >/dev/null 2>&1; then
            echo "[*] Installing Homebrew (requires Xcode Command Line Tools)"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
}