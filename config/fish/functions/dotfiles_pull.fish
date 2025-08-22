function dotfiles_pull --description "Pull dotfiles updates"
    if test -f ~/.cache/dotfiles-updates-available
        set commit_count (cat ~/.cache/dotfiles-updates-available)
        echo "Pulling $commit_count dotfiles updates..."
        if ~/dotfiles/pull.sh
            echo "dotfiles: Updated successfully"
            rm -f ~/.cache/dotfiles-updates-available
        else
            echo "dotfiles: Pull failed - check manually"
        end
    else
        echo "No dotfiles updates available"
    end
end