# dotfiles

Personal dotfiles for macOS and Linux. Sets up fish shell, tmux, vim, dev tooling, and [pi](https://github.com/mariozechner/pi) (my favorite CLI coding agent).

## What gets installed

- **Shell**: fish (set as default), zoxide, custom aliases
- **Editor**: vim (amix/vimrc)
- **Terminal**: tmux, ghostty config, terminfo
- **Languages**: Rust (rustup), Node.js LTS (nvm), Python (uv)
- **CLI tools**: bat, fzf, ripgrep, gh, ncdu, htop, tree, and optionally cargo packages (git-delta, samply, bottom, etc.)
- **Coding**: [pi-coding-agent](https://github.com/mariozechner/pi) installed globally via npm

## Setup

```bash
git clone https://github.com/j-carin/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
```

The setup script is interactive — it will prompt before each major step. Use `./setup.sh -y` to auto-accept everything.

## Secrets (optional)

The `secrets/` directory is a private git submodule ([j-carin/dotfiles-secrets](https://github.com/j-carin/dotfiles-secrets)) containing API keys and credentials loaded as environment variables via `secrets/secrets.env`. It also contains a gdrive config.

If you don't have access to the secrets repo, everything still works fine — the submodule init will be skipped automatically, and no env vars will be loaded.

To set it up if you do have access:

```bash
git submodule update --init --recursive
```

## Updating

Fish shell checks for dotfiles updates on startup. When updates are available:

```bash
dotfiles_pull
```

Or manually:

```bash
cd ~/dotfiles
git pull
./ln.sh
```
