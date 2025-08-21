function claude_commit
    # Check if we're in a git repository
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "Error: not a git repository"
        return 1
    end
    
    set staged_files (git diff --cached --name-only)
    if test (count $staged_files) -eq 0
        return 1
    end
    
    set temp_file (mktemp)
    echo "Write a git commit message in conventional commit format for these changes. Output ONLY the commit message:" > $temp_file
    echo "" >> $temp_file
    echo "Format: <type>[(scope)]: <brief description> (max 50 chars)" >> $temp_file
    echo "Use scope when multiple modules affected (e.g., fix(auth): ...)" >> $temp_file
    echo "" >> $temp_file
    echo "- Bullet point list of key changes (max 72 chars per line)" >> $temp_file
    echo "- Focus on important parts, not every detail" >> $temp_file
    echo "- Skip trivial changes (formatting, imports, renames)" >> $temp_file
    echo "" >> $temp_file
    echo "Types: feat (new feature), fix (bug fix), docs (documentation), style (formatting), refactor (code restructure), test (tests), chore (maintenance)" >> $temp_file
    echo "" >> $temp_file
    echo "Be specific but concise. Mention key functions/behaviors changed, but don't list every single modification." >> $temp_file
    echo "" >> $temp_file
    echo "Git status:" >> $temp_file
    git status --short >> $temp_file
    echo "" >> $temp_file
    echo "Git diff:" >> $temp_file
    git diff --cached --no-color >> $temp_file
    
    set output_file (mktemp)
    claude --model claude-3-5-haiku-latest --print < $temp_file > $output_file
    rm $temp_file
    
    if test ! -s "$output_file"
        rm $output_file
        return 1
    end
    
    # Check if we're in an interactive terminal
    if isatty
        # Open in vim for editing
        vim $output_file
        
        # Check if file still exists and has content after vim
        if test -s "$output_file"
            git commit -F "$output_file"
        else
            echo "Commit cancelled"
        end
    else
        # Non-interactive: show message and prompt y/n
        cat $output_file
        echo
        read -P "Commit with this message? (y/n): " -n 1 confirm
        if test "$confirm" = "y"
            cat $output_file | git commit -F -
        else
            echo "Commit cancelled"
        end
    end
    
    rm -f $output_file
end
