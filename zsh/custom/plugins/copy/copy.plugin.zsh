#!/usr/bin/env zsh

# ------------------------------------------------------------------------------
# (Copied from OMZ)
# (https://github.com/ohmyzsh/ohmyzsh/)
# ------------------------------------------------------------------------------

function clipcopy() { pbcopy <"${1:-/dev/stdin}"; }

function copydir {
  emulate -L zsh
  print -n $PWD | clipcopy
}

function copyfile {
  emulate -L zsh
  clipcopy $1
}

function copybuffer() {
  if which clipcopy &>/dev/null; then
    printf "%s" "$BUFFER" | clipcopy
  else
    zle -M "clipcopy not found. Please make sure you have Oh My Zsh installed correctly."
  fi
}

zle -N copybuffer

bindkey -M emacs "^O" copybuffer
bindkey -M viins "^O" copybuffer
bindkey -M vicmd "^O" copybuffer
