#!/usr/bin/env bash
set -euo pipefail

# Load shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPT_DIR/setup-common.sh"

# Ensure Homebrew exists
ensure_homebrew

# Prompt for package installation
prompt_user $'\nUpdate Homebrew and install core packages? [y/N] '

if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    # Install core packages (now includes gh that was missing)
    install_packages "${CORE_PACKAGES[@]}"
fi

# Install platform-specific tools
install_platform_specific
