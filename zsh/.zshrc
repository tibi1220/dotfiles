#!/usr/bin/env zsh

# Source own files
source "$ZDOTDIR/.zsh/env.zsh"
source "$ZDOTDIR/.zsh/options.zsh"
source "$ZDOTDIR/.zsh/prompt.zsh"
source "$ZDOTDIR/.zsh/functions/functions.zsh"

# Source plugins (from custom directory)
zsh_source_custom

# Source plugins (from git)
zsh_add_plugin "zsh-users/zsh-autosuggestions"
zsh_add_plugin "hlissner/zsh-autopair"
zsh_add_plugin "zsh-users/zsh-syntax-highlighting"
