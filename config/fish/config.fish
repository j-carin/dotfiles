set -g fish_greeting
set -U EDITOR vim

if not contains "$HOME/.cargo/bin" $PATH
    set -gx PATH "$HOME/.cargo/bin" $PATH
end

if not contains "$HOME/.local/bin" $PATH
    set -gx PATH "$HOME/.local/bin" $PATH
end

# Node.js and npm configuration
if test -f ~/.nvmrc
    nvm use (cat ~/.nvmrc) --silent 2>/dev/null
end

# Add npm global bin to PATH
if command -q npm
    if not contains (npm config get prefix)/bin $PATH
        set -gx PATH (npm config get prefix)/bin $PATH
    end
end

# Load environment variables from secrets
if test -f "$HOME/dotfiles/secrets/secrets.env"
    for line in (cat "$HOME/dotfiles/secrets/secrets.env")
        # Skip empty lines and comments
        if test -n "$line" -a (string sub -s 1 -l 1 -- "$line") != "#"
            # Split on first = and export
            set key_value (string split -m 1 "=" -- "$line")
            if test (count $key_value) -eq 2
                set -gx $key_value[1] $key_value[2]
            end
        end
    end
end

zoxide init fish --cmd cd | source
if test -x /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv | source
    # Disable Homebrew auto-update when installing packages
    set -gx HOMEBREW_NO_AUTO_UPDATE 1
end

alias copy='fish_clipboard_copy'
alias paste='fish_clipboard_paste'

# For blinking cursor – only in interactive shells so that
# non-interactive programs such as rsync do not see stray bytes
if status is-interactive
    echo -ne "\e[5 q"
    dotfiles_sync_check
    set behind_count (git -C ~/dotfiles rev-list --count HEAD..@{upstream} 2>/dev/null || echo "0")
    if test "$behind_count" -gt 0
        echo "dotfiles: Updates available ($behind_count commits). Type 'dotfiles_pull' to update."
    end
end
