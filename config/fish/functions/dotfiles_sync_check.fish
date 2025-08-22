function dotfiles_sync_check --description "Check for dotfiles updates in background"
    if status is-interactive
        ~/dotfiles/scripts/tools/dotfiles-sync.sh &
        disown
    end
end