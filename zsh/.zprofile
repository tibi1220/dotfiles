#!/usr/bin/env zsh

# Build the login environment before applying login-only exports. Interactive
# login shells will skip the guarded environment file when .zshrc runs later.
source "$ZDOTDIR/.zsh/env.zsh"
source "$ZDOTDIR/.zsh/exports.zsh"
