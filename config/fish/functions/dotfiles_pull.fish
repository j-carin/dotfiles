function dotfiles_pull --description "Pull dotfiles updates"
    set behind_count (git -C ~/dotfiles rev-list --count HEAD..@{upstream} 2>/dev/null || echo "0")
    if test "$behind_count" -gt 0
        echo "Pulling $behind_count dotfiles updates..."
        if ~/dotfiles/pull.sh
            echo "dotfiles: Updated successfully"
        else
            echo "dotfiles: Pull failed - check manually"
        end
    else
        echo "No dotfiles updates available"
    end
end