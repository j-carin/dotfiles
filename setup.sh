#!/usr/bin/env bash

dir=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

read -p $'\nUpdate apt and install core packages? [y/N] ' -r
if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    sudo apt update && sudo apt -y upgrade
    sudo apt install -y git curl wget vim htop tree

    # fancier packages
    sudo apt install -y bat fzf ripgrep ncdu
fi

# Install Vim config
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh

# Link dotfiles
ln -sf "$dir/gitconfig" ~/.gitconfig
ln -sf "$dir/gitignore" ~/.gitignore
ln -sf "$dir/bash_aliases" ~/.bash_aliases
ln -sf "$dir/.config/fish/config.fish" ~/.config/fish/config.fish

# Install Rust
if ! command -v rustc &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# Install uv
if ! command -v uv &> /dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Install zoxide
if ! command -v zoxide &> /dev/null; then
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    echo "eval \"\$(zoxide init bash --cmd cd)\"" >> ~/.bashrc
    echo "export _ZO_DOCTOR=0" >> ~/.bashrc
fi

# Install Rust CLI tools
read -p $'\nInstall cargo packages? This is slow. [y/N] ' -r
if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    . "$dir/cargo-setup.sh"
fi

# Install magic-trace
if ! command -v magic-trace &> /dev/null; then
    arch=$(uname -m)
    if [[ "$arch" != "x86_64" ]]; then
        echo "[-] magic-trace only supports x86_64 architectures. Skipping install."
    else
        mkdir -p ~/.local/bin
        curl -Lo ~/.local/bin/magic-trace https://github.com/janestreet/magic-trace/releases/download/v1.2.4/magic-trace
        chmod +x ~/.local/bin/magic-trace
    fi
fi

# Prompt to change default shell to fish
if command -v fish &> /dev/null; then
    read -p $'\nChange default shell to fish? [y/N] ' -r
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        fish_path=$(command -v fish)

        # Add fish to /etc/shells if missing
        if ! grep -qx "$fish_path" /etc/shells; then
            echo "[*] Adding $fish_path to /etc/shells (requires sudo)"
            echo "$fish_path" | sudo tee -a /etc/shells > /dev/null
        fi

        chsh -s "$fish_path" && echo "[+] Default shell changed to: $fish_path"

        echo "Launching fish..."
        exec fish
    fi
fi
