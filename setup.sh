dir=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

read -p $'\nUpdate apt and install core packages? [y/N] ' -r
if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    sudo apt update && sudo apt -y upgrade
    sudo apt install -y git curl wget vim htop tree
fi

# vimrc
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh

# install dotfiles
ln -sf "$dir/gitconfig" ~/.gitconfig
ln -sf "$dir/gitignore" ~/.gitignore
ln -sf "$dir/bash_aliases" ~/.bash_aliases

# setup rust
if ! command -v rustc &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# install uv
if ! command -v uv &> /dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then # sourced
    source ~/.bashrc
else # not sourced
    echo "To apply shell changes, run:"
    echo "    source ~/.bashrc"
fi
