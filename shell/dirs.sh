# Shared dotfile and project directories, for every zsh/bash process
# (including scripts). Sourced by zsh's .zshenv and bash's .bashrc/.bash_profile.

export CONFIGDIR="$HOME/.config"
# Where this repository lives. .zshenv and .bashrc set it from their own real
# path before sourcing this file, so no ~/.config/shell link is needed.
export DOTFILESDIR="${DOTFILESDIR:-$HOME/dotfiles}"
export SHELLDIR="$DOTFILESDIR/shell"
export CODEDIR="$HOME/Documents/Code"
export LATEXDIR="$HOME/Documents/LaTeX"
export WORKDIR="$HOME/Documents/WORK"
export VIMDIR="$DOTFILESDIR/nvim"
export VIMRC="$VIMDIR/init.lua"
export THEOS="$HOME/theos"

# Disable macOS Terminal session restore files
export SHELL_SESSIONS_DISABLE=1
