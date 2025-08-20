#!/usr/bin/env bash
set -euo pipefail

# Load shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPT_DIR/common.sh"

# Prompt for package installation
prompt_user $'\nUpdate apt and install core packages? [y/N] '

if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    # Combine core packages with Linux-specific ones
    ALL_PACKAGES=("${CORE_PACKAGES[@]}" "${LINUX_SPECIFIC[@]}")
    install_packages "${ALL_PACKAGES[@]}"
fi

# Install platform-specific tools
install_platform_specific
