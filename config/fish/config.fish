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

zoxide init fish --cmd cd | source
if test -x /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv | source
end

alias copy='fish_clipboard_copy'
alias paste='fish_clipboard_paste'

# For blinking cursor
echo -ne "\e[5 q"
