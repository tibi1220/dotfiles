#! /usr/bin/env zsh

# Colorize grep output (good for log files)
alias grep='grep --color=auto'
alias egrep='grep -E --color=auto'
alias fgrep='grep -F --color=auto'

# Colored ls
alias ls='ls --color=auto'
alias la='eza --icons -a'
alias ll='eza --icons --group-directories-first -Bla'
alias llg='eza --icons --group-directories-first --git -Bla'

# Most used directories
alias r='cd /'
alias c='cd "$CODEDIR"'
alias l='cd "$LATEXDIR"'
alias w='cd "$WORKDIR"'
alias z='cd "$ZDOTDIR"'
alias v='cd "$VIMDIR"'
alias bme='cd ~/Documents/00BMEGE'
alias cme='cd ~/Documents/00BMEGE/2026-27'

# History
alias hist="history -E"
alias sist="history -E 0 | grep"
