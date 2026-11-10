#!/usr/bin/env zsh

# Source own files
source "$ZDOTDIR/lib/env.zsh"
source "$ZDOTDIR/lib/options.zsh"
source "$ZDOTDIR/lib/prompt.zsh"
source "$ZDOTDIR/lib/functions/functions.zsh"

# Source plugins (from custom directory)
zsh_source_custom

# fzf keybindings and completion (if installed)
source "$ZDOTDIR/lib/fzf.zsh"

# Source plugins (from git)
zsh_add_plugin "zsh-users/zsh-autosuggestions"
zsh_add_plugin "hlissner/zsh-autopair"
zsh_add_plugin "zsh-users/zsh-syntax-highlighting"
