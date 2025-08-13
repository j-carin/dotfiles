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
    echo "Write a git commit message in conventional commit format for these changes. Output ONLY the commit message and nothing else:" > $temp_file
    echo "" >> $temp_file
    echo "Format: <type>: <brief description>" >> $temp_file
    echo "" >> $temp_file
    echo "<detailed list of changes>" >> $temp_file
    echo "" >> $temp_file
    echo "Types: feat (new feature), fix (bug fix), docs (documentation), style (formatting), refactor (code restructure), test (tests), chore (maintenance), or pick another type if applicable" >> $temp_file
    echo "" >> $temp_file
    echo "IMPORTANT: Be specific about what changed. Instead of vague descriptions like 'improve error handling', use concrete details like 'add git repo validation check' or 'replace interactive confirmation with direct stdin commit'. Focus on actual code changes, function names, and specific behaviors modified." >> $temp_file
    echo "" >> $temp_file
    echo "Git status:" >> $temp_file
    git status --short >> $temp_file
    echo "" >> $temp_file
    echo "Detailed changes:" >> $temp_file
    git diff --cached --no-color >> $temp_file
    
    set output_file (mktemp)
    claude --model sonnet --print < $temp_file > $output_file
    rm $temp_file
    
    if test ! -s "$output_file"
        rm $output_file
        return 1
    end
    
    cat $output_file
    rm $output_file
end