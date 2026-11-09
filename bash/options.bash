# History: large, shared between open shells, no duplicates, with timestamps.
HISTFILE="$BASHDIR/.bash_history"
HISTSIZE=120000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups # skip duplicates and lines starting with a space
HISTTIMEFORMAT='%F %T  '
shopt -s histappend cmdhist

alias hist='history'
alias sist='history | grep'

# Typing a directory name cd's into it; small typos in paths are corrected.
shopt -s autocd cdspell dirspell
# `**` matches recursively; extended patterns like !(*.log)
shopt -s globstar extglob
# Update LINES/COLUMNS after each command
shopt -s checkwinsize
