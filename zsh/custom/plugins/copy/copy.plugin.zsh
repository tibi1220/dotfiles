#!/usr/bin/env zsh

# ------------------------------------------------------------------------------
# (Adapted from OMZ)
# (https://github.com/ohmyzsh/ohmyzsh/)
# ------------------------------------------------------------------------------

# clipcopy, clippaste, copydir, copyfile and detect-clipboard are shared with
# bash: see $SHELLDIR/functions/clipboard.sh.

# Copy the current command line (Ctrl-O)
function copybuffer() {
  if (( $+functions[clipcopy] )); then
    printf "%s" "$BUFFER" | clipcopy
  else
    zle -M "clipcopy not found. Run detect-clipboard."
  fi
}

zle -N copybuffer

bindkey -M emacs "^O" copybuffer
bindkey -M viins "^O" copybuffer
bindkey -M vicmd "^O" copybuffer
