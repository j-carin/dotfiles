# CLAUDE.md

This file provides guidance when working with code in this repository.

## CRITICAL RULES - READ FIRST

1. **ALWAYS read existing code before making ANY changes**
   - Read the full script you're modifying
   - Read related scripts (setup.sh, ln.sh, etc.)
   - Understand the existing patterns and architecture

2. **Shell compatibility matters**
   - Setup scripts are bash - don't mix syntaxes
   - Fish functions use fish syntax only
   - Test syntax compatibility (heredocs don't work in fish)

3. **Follow established patterns**
   - Configuration: use `config/` + `ln.sh` symlinks ONLY
   - Don't duplicate functionality that already exists
   - If unsure, grep the codebase to see how similar tasks are handled

## Repository Overview

This is a personal dotfiles repository for configuring development environments across Linux and macOS systems. The setup scripts automate the installation of development tools and configuration of shell environments.

## Key Commands

### Setup and Installation
- `./setup.sh` - Main setup script that detects OS and runs appropriate platform-specific setup (supports `-y` flag for unattended install)
- `./scripts/setup/common.sh` - Shared utilities and package lists used by platform-specific scripts
- `./scripts/setup/linux.sh` - Linux-specific package installation (uses apt with fish-shell PPA) - sources common.sh
- `./scripts/setup/mac.sh` - macOS-specific package installation (uses Homebrew) - sources common.sh
- `./scripts/tools/cargo.sh` - Installs Rust CLI tools (git-delta, samply, code2prompt, ffsend, procs, bottom)
- `./scripts/tools/dotfiles-sync.sh` - Background script to fetch dotfiles updates
- `./ln.sh` - Creates symbolic links for all configuration files
- `./pull.sh` - Hard resets to origin/main and re-runs ln.sh (warns about uncommitted changes)

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
2. Platform scripts source `common.sh` for shared utilities and package lists
3. Platform scripts install core packages using shared abstractions
4. Platform-specific tools and fixes are applied:
   - **Linux**: magic-trace (x86_64), bat->batcat symlink, Linux-specific packages (pkg-config, libssl-dev)
   - **macOS**: Homebrew setup
5. Git submodules initialized (for secrets)
6. Optional: passwordless sudo configuration
7. Vim configuration (amix/vimrc) installed
8. Rust toolchain, uv (Python), and zoxide installed cross-platform
9. User is prompted for optional Rust CLI tools installation
10. `ln.sh` creates symbolic links for all dotfiles
11. Ghostty terminfo compiled to ~/.terminfo
12. Optional shell change to fish with proper configuration
13. If fish is chosen, user is prompted for optional OpenCode installation

### Shared Utilities (`common.sh`)
The setup system uses shared utilities to reduce code duplication:
- `CORE_PACKAGES` - Common packages: git, curl, wget, vim, htop, tree, bat, fzf, ripgrep, ncdu, fish, tmux, gh
- `LINUX_SPECIFIC` - Additional packages only needed on Linux: pkg-config, libssl-dev
- `prompt_user()` - Consistent user prompt handling with AUTO_YES support
- `install_packages()` - Package manager abstraction (apt vs brew)
- `install_platform_specific()` - Platform-specific tool installation and fixes
- `ensure_homebrew()` - macOS Homebrew installation helper

**Platform-specific fixes handled automatically:**
- **Linux**: Creates `bat` symlink (Ubuntu installs as `batcat`), installs magic-trace on x86_64
- **macOS**: No package name conflicts, `bat` installs correctly via Homebrew

### Configuration Structure

**Dotfiles** (linked to ~/):
- `config/gitconfig` -> `~/.gitconfig` - Git config with delta pager, aliases (s, co, br, c, st, lg)
- `config/gitignore` -> `~/.gitignore` - Global gitignore (editors, builds, caches, secrets)
- `config/bash_aliases` -> `~/.bash_aliases` - Bash aliases (ll, la, l, rm -I, .., ...)
- `config/tmux.conf` -> `~/.tmux.conf` - tmux config (prefix C-x, vi copy mode, OSC52 clipboard)

**Terminal** (linked to ~/.config/):
- `config/ghostty/config` -> `~/.config/ghostty/config` - Ghostty theme (catppuccin-mocha)
- `config/terminfo/xterm-ghostty.src` - Compiled to ~/.terminfo for proper terminal support

**Fish Shell** (linked to ~/.config/fish/):
- `config/fish/config.fish` - Main config: PATH setup, SSH agent socket management, nvm activation, secrets loading, zoxide init, Homebrew setup, dotfiles update check
- `config/fish/functions/opencode.fish` - Wrapper that sets `OPENCODE_EXPERIMENTAL_LSP_TY=1`
- `config/fish/functions/dotfiles_pull.fish` - Pull dotfiles updates
- `config/fish/functions/dotfiles_sync_check.fish` - Background check for dotfiles updates

**OpenCode** (linked to ~/.config/opencode/):
- `config/opencode/opencode.json` -> `~/.config/opencode/opencode.json` - OpenCode config (leader key: ctrl+l)
- `config/opencode/AGENTS.md` -> `~/.config/opencode/AGENTS.md` - Global guidelines (use uv for Python)
- `skills/` -> `~/.config/opencode/skill` - OpenCode skills directory

**Secrets** (git submodule):
- `secrets/gdrive3` -> `~/.config/gdrive3` - Google Drive credentials
- `secrets/secrets.env` - Environment variables loaded by fish config

### OpenCode Skills
- `skills/web-search/` - Web search skill using GPT-5.2 with high reasoning
  - `SKILL.md` - Skill description and usage instructions
  - `search.py` - Python script using OpenAI API with web_search tool

### Git Aliases (from gitconfig)
- `git s` - Short status
- `git co` - Checkout
- `git br` - Branch
- `git c "msg"` - Commit with message
- `git st` - Status
- `git lg` - Pretty log graph

### Development Tools Installed
- Core: git, curl, wget, vim, htop, tree, gh (GitHub CLI)
- Modern alternatives: bat (cat), fzf (fuzzy finder), ripgrep (grep), ncdu (du)
- Terminal: tmux, fish shell, Ghostty terminal
- Rust toolchain with cargo
- Python package manager: uv
- Smart directory navigation: zoxide
- Git pager: delta (side-by-side diffs)
- Optional Rust CLI tools: git-delta, samply, code2prompt, ffsend, procs, bottom
- AI tools: OpenCode

The setup is designed to be idempotent and can be run multiple times safely.
