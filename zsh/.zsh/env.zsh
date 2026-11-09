#!/usr/bin/env zsh

# This file is sourced by both .zprofile and .zshrc.
[[ -n ${_DOTFILES_ENV_LOADED:-} ]] && return
typeset -g _DOTFILES_ENV_LOADED=1

# Custom directories for zsh
export ZSH_CUSTOM_PLUGINS=$ZDOTDIR/custom/plugins
export ZSH_PLUGINS=$ZDOTDIR/plugins
export ZSHRC=$ZDOTDIR/.zshrc

# Keep PATH entries unique across shell reloads.
typeset -U path PATH

# PATH, Homebrew, pnpm, editor, NVIM_PROFILE (shared with bash)
source "$SHELLDIR/env.sh"
