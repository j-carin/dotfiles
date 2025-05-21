set -g fish_greeting
set -U EDITOR vim

if not contains "$HOME/.cargo/bin" $PATH
    set -gx PATH "$HOME/.cargo/bin" $PATH
end

if not contains "$HOME/.local/bin" $PATH
    set -gx PATH "$HOME/.local/bin" $PATH
end

zoxide init fish --cmd cd | source
