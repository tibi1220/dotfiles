#!/usr/bin/env zsh

# Use nvim instead of vim
alias vim='nvim'

# Colorize grep output (good for log files)
alias grep='grep --color=auto'
alias egrep='grep -E --color=auto'
alias fgrep='grep -F --color=auto'

# Confirm before overwriting something
# alias cp="cp -i"
# alias mv='mv -i'
# alias rm='rm -i'

# Colored ls
alias ls='ls --color=auto'
alias la='eza --icons -a'
alias ll='eza --icons --group-directories-first -Bla'
alias llg='eza --icons --group-directories-first --git -Bla'

# Change to working directories
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

# Homebrew aliases
alias bup="brew update && brew upgrade"
alias bslist="brew services list"
alias bsstart="brew services start"
alias bsstop="brew services stop"

# Git aliases
alias gs="git status"
alias ga="git add"
alias gaa="git add --all"
alias gc="git commit -S -m"
alias gp="git push"

# Other aliases
alias lg="lazygit"
alias m-dl="yt-dlp --extract-audio --audio-format mp3"
