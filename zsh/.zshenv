#!/usr/bin/env zsh

# zsh config dir
export ZDOTDIR="$HOME/.config/zsh"

# Shared dotfile and project directories. Keep these available to login,
# interactive, and script-driven zsh processes.
export CONFIGDIR="$HOME/.config"
export CODEDIR="$HOME/Documents/Code"
export LATEXDIR="$HOME/Documents/LaTeX"
export WORKDIR="$HOME/Documents/WORK"
export VIMDIR="$CONFIGDIR/nvim"
export VIMRC="$VIMDIR/init.lua"
export THEOS="$HOME/theos"

# Disable sessions
export SHELL_SESSIONS_DISABLE=1
