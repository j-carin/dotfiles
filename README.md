# dotfiles

Personal dotfiles for macOS and Linux. Fish shell, tmux, vim, dev tooling, and [pi](https://github.com/mariozechner/pi).

## Setup

```bash
git clone https://github.com/j-carin/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh        # interactive, or ./setup.sh -y to auto-accept
```

## Secrets

`secrets/` is a private submodule with API keys and credentials (`secrets.env`). Setup skips it gracefully if it's not cloned.

## Updating

Fish checks for updates on startup. Run `dotfiles_pull` or:

```bash
cd ~/dotfiles && git pull && ./ln.sh
```
