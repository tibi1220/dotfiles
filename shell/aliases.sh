# Aliases shared by zsh and bash.

alias sudo='sudo '

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
alias v='cd "$VIMDIR"'
alias d='cd "$DOTFILESDIR"'
alias bme='cd ~/Documents/00BMEGE'
alias cme='cd ~/Documents/00BMEGE/2026-27'

# Git
alias gs="git status"
alias ga="git add"
alias gaa="git add --all"
alias gc="git commit -S -m"
alias gp="git push"
alias lg="lazygit"

# Neovim
alias vim="nvim"

# tmux (the session picker is in functions/tmux.sh)
alias t='tmux'
alias ta='tmux attach -t'
alias tn='tmux new-session -s'
alias tl='tmux ls'
alias tk='tmux kill-session -t'
alias tka='tmux kill-server'

# Homebrew (macOS only)
if [[ $OSTYPE == darwin* ]]; then
  alias bup="brew update && brew upgrade"
  alias bslist="brew services list"
  alias bsstart="brew services start"
  alias bsstop="brew services stop"
fi
