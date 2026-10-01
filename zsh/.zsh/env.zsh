#!/usr/bin/env zsh

# This file is sourced by both .zprofile and .zshrc.
[[ -n ${_DOTFILES_ENV_LOADED:-} ]] && return
typeset -g _DOTFILES_ENV_LOADED=1

# Custom directories for zsh
export ZSH_CUSTOM_PLUGINS=$ZDOTDIR/custom/plugins
export ZSH_PLUGINS=$ZDOTDIR/plugins
export ZSHRC=$ZDOTDIR/.zshrc

# Build PATH as an array so entries remain unique across shell reloads.
typeset -U path PATH
typeset -gx PNPM_HOME="$HOME/Library/pnpm"

if [[ -d /opt/homebrew ]]; then
  typeset -gx HOMEBREW_PREFIX=/opt/homebrew
elif [[ -d /usr/local/Homebrew ]]; then
  typeset -gx HOMEBREW_PREFIX=/usr/local
fi

if [[ -n $HOMEBREW_PREFIX ]]; then
  typeset -gx HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
  typeset -gx HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX"
  typeset -gx MANPATH="$HOMEBREW_PREFIX/share/man${MANPATH+:$MANPATH}:"
  typeset -gx INFOPATH="$HOMEBREW_PREFIX/share/info${INFOPATH:+:$INFOPATH}"
  path=("$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin" $path)
fi

[[ -d /Library/Frameworks/Python.framework/Versions/3.13/bin ]] &&
  path=(/Library/Frameworks/Python.framework/Versions/3.13/bin $path)

path=("$HOME/.local/bin" "$HOME/.cargo/bin" "$PNPM_HOME" $path)

# Code editors
export EDITOR=nvim
export VISUAL=nvim
