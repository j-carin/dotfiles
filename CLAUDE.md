# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## CRITICAL RULES - READ FIRST

1. **ALWAYS read existing code before making ANY changes**
   - Read the full script you're modifying
   - Read related scripts (setup.sh, ln.sh, etc.)
   - Understand the existing patterns and architecture

2. **Shell compatibility matters**
   - `setup-ai.sh` is fish shell script - use fish syntax only
   - Other setup scripts are bash - don't mix syntaxes
   - Test syntax compatibility (heredocs don't work in fish)

3. **Follow established patterns**
   - Configuration: use `config/` + `ln.sh` symlinks ONLY
   - Don't duplicate functionality that already exists
   - If unsure, grep the codebase to see how similar tasks are handled

## Repository Overview

This is a personal dotfiles repository for configuring development environments across Linux and macOS systems. The setup scripts automate the installation of development tools and configuration of shell environments.

## Key Commands

### Setup and Installation
- `./setup.sh` - Main setup script that detects OS and runs appropriate platform-specific setup
- `./setup-linux.sh` - Linux-specific package installation (uses apt)
- `./setup-mac.sh` - macOS-specific package installation (uses Homebrew)
- `./cargo-setup.sh` - Installs additional Rust CLI tools (git-delta, samply, code2prompt, etc.)
- `./setup-ai.sh` - Installs AI tools (Claude Code CLI and OpenAI Codex) with Node.js via nvm.fish
- `./ln.sh` - Creates symbolic links for all configuration files

### Configuration Management
**CRITICAL**: This repository uses ONLY symbolic linking for configuration management via `ln.sh`. 

**NEVER create configuration files directly** - all configs must be:
1. Created in the appropriate `config/` subdirectory in this repo
2. Linked via `ln.sh` (which runs automatically during setup)

**Before modifying any config-related code, ALWAYS check:**
- What's already in `config/` directory
- How `ln.sh` handles that config type
- Follow the existing symlink pattern

## Architecture

### Setup Flow
1. Main `setup.sh` detects OS and delegates to platform-specific scripts
2. Platform scripts install core packages and tools
3. Common tools (Rust, uv, zoxide, Vim configuration) are installed cross-platform
4. User is prompted for optional Rust CLI tools installation
5. `ln.sh` creates symbolic links for all dotfiles
6. Optional shell change to fish with proper configuration
7. If fish is chosen, user is prompted for optional AI tools installation

### AI Tools Setup
The `setup-ai.sh` script handles the complete installation of AI development tools:
- Installs Fisher plugin manager for fish shell
- Installs nvm.fish for Node.js version management
- Installs Node.js 22 and sets it as default via ~/.nvmrc
- Configures fish to auto-activate Node.js and adds npm global bin to PATH
- Installs @anthropic-ai/claude-code and @openai/codex globally via npm
- OpenAI Codex configuration is already managed by ln.sh symlink system
- Verifies installation and provides usage instructions

### Configuration Structure
- `config/fish/config.fish` - Fish shell configuration with PATH management and tool initialization
- `config/tmux.conf` - tmux configuration with custom prefix (C-x) and clipboard integration
- `config/ghostty/config` - Terminal emulator theme configuration
- `config/codex/config.json` - OpenAI Codex configuration with o3 model and full-auto approval mode
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