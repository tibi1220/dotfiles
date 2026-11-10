# bash configuration: a lighter companion to the zsh setup.
# ~/.bashrc and ~/.bash_profile are symlinks into this folder.

# The repository is the parent of this file's real folder (~/.bashrc is a
# symlink to .../dotfiles/bash/.bashrc).
__bashrc=$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null) && export DOTFILESDIR=${__bashrc%/bash/*}
unset __bashrc

# Directory variables and environment shared with zsh
source "${DOTFILESDIR:-$HOME/dotfiles}/shell/dirs.sh"
source "$SHELLDIR/env.sh"

# Everything below is for interactive shells only
[[ $- == *i* ]] || return

export BASHDIR="$DOTFILESDIR/bash"

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
