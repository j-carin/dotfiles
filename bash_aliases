if which lsd &> /dev/null; then
    alias ls='lsd'
    alias ll='lsd -la'
    alias la='lsd -a'
    alias l='lsd -F'
else
    alias ll='ls -lagF'
    alias la='ls -A'
    alias l='ls -F'
fi


alias rm='rm -I'

alias ..='cd ..'
alias ...='cd .. && cd ..'

