#!/usr/bin/env zsh

# zsh config dir
export ZDOTDIR="$HOME/.config/zsh"

# The repository is the parent of the zsh folder; :A follows the
# ~/.config/zsh symlink to ~/dotfiles/zsh.
export DOTFILESDIR=${ZDOTDIR:A:h}

# Directory variables shared with bash (CODEDIR, SHELLDIR, ...).
# Available to login, interactive, and script-driven zsh processes.
source "$DOTFILESDIR/shell/dirs.sh"
