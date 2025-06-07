# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for configuring development environments across Linux and macOS systems. The setup scripts automate the installation of development tools and configuration of shell environments.

## Key Commands

### Setup and Installation
- `./setup.sh` - Main setup script that detects OS and runs appropriate platform-specific setup
- `./setup-linux.sh` - Linux-specific package installation (uses apt)
- `./setup-mac.sh` - macOS-specific package installation (uses Homebrew)
- `./cargo-setup.sh` - Installs additional Rust CLI tools (git-delta, samply, code2prompt, etc.)
- `./claude-setup.sh` - Installs Claude Code CLI with Node.js via nvm.fish
- `./ln.sh` - Creates symbolic links for all configuration files

### Configuration Management
The repository uses symbolic linking to manage dotfiles. All configurations are linked from this repository to their expected locations in the home directory.

## Architecture

### Setup Flow
1. Main `setup.sh` detects OS and delegates to platform-specific scripts
2. Platform scripts install core packages and tools
3. Common tools (Rust, uv, zoxide, Vim configuration) are installed cross-platform
4. User is prompted for optional Rust CLI tools installation
5. `ln.sh` creates symbolic links for all dotfiles
6. Optional shell change to fish with proper configuration
7. If fish is chosen, user is prompted for optional Claude Code CLI installation

### Claude Code CLI Setup
The `claude-setup.sh` script handles the complete installation of Claude Code CLI:
- Installs Fisher plugin manager for fish shell
- Installs nvm.fish for Node.js version management
- Installs Node.js 22 and sets it as default via ~/.nvmrc
- Configures fish to auto-activate Node.js and adds npm global bin to PATH
- Installs @anthropic-ai/claude-code globally via npm
- Verifies installation and provides usage instructions

### Configuration Structure
- `config/fish/config.fish` - Fish shell configuration with PATH management and tool initialization
- `config/tmux.conf` - tmux configuration with custom prefix (C-x) and clipboard integration
- `config/ghostty/config` - Terminal emulator theme configuration
- `gitconfig` and `gitignore` - Git configuration files
- `bash_aliases` - Bash alias definitions

### Development Tools Installed
- Core: git, curl, wget, vim, htop, tree
- Modern alternatives: bat (cat), fzf (fuzzy finder), ripgrep (grep), ncdu (du)
- Rust toolchain with cargo
- Python package manager: uv
- Smart directory navigation: zoxide
- Optional Rust CLI tools: git-delta, samply, code2prompt, ffsend, procs, bottom

The setup is designed to be idempotent and can be run multiple times safely.