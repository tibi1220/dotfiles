# bash configuration: a lighter companion to the zsh setup.
# ~/.bashrc and ~/.bash_profile are symlinks into this folder.

# Directory variables and environment shared with zsh
source "$HOME/.config/shell/dirs.sh"
source "$SHELLDIR/env.sh"

# Everything below is for interactive shells only
[[ $- == *i* ]] || return

export BASHDIR="$CONFIGDIR/bash"

if (( BASH_VERSINFO[0] < 4 )); then
  echo "bash $BASH_VERSION is too old for this config (macOS /bin/bash);" \
    "run Homebrew's bash instead: brew install bash" >&2
  return
fi

source "$BASHDIR/options.bash"
source "$BASHDIR/prompt.bash"
source "$SHELLDIR/init.sh"
source "$BASHDIR/completion.bash"
source "$BASHDIR/fzf.bash"
source "$BASHDIR/keybindings.bash"

alias b='cd "$BASHDIR"'
alias bash-reload='exec bash'
