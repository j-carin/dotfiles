#!/usr/bin/env bash
if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
else
    echo "Rust environment not found. Did rustup install fail?"
    exit 1
fi

# Update Rust to latest stable version
echo "[*] Updating Rust toolchain..."
rustup update

mkdir -p ~/.local/bin
export PATH="$HOME/.cargo/bin:$PATH"

cargo install \
    git-delta \
    samply \
    code2prompt \
    ffsend \
    procs \
    bottom
