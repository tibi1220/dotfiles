# Over SSH, the terminal's title starts with the host, so kitty's tab and
# window title show where the shell runs:
#   at the prompt:       [homepi] ~/dotfiles
#   while a command runs: [homepi] nvim README.md
# Locally kitty's shell integration sets the title, and inside tmux tmux
# does (set-titles-string in tmux.conf), so this is only for SSH outside tmux.
[[ -n $SSH_CONNECTION && -z $TMUX ]] || return 0

autoload -Uz add-zsh-hook

# OSC 2 sets the title; control characters in a command would end it early
function _ssh_title() {
  print -rn -- $'\e]2;'"[${HOST%%.*}] ${1//[[:cntrl:]]/ }"$'\a'
}

function _ssh_title_precmd() {
  _ssh_title "${(%):-%~}"
}

# $1 is the command line as typed, cut to 50 characters
function _ssh_title_preexec() {
  local cmd=$1
  ((${#cmd} > 50)) && cmd="${cmd[1,49]}…"
  _ssh_title "$cmd"
}

add-zsh-hook precmd _ssh_title_precmd
add-zsh-hook preexec _ssh_title_preexec
