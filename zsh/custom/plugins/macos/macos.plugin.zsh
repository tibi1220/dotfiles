#!/usr/bin/env zsh

# macOS helpers: cdf and man-preview. (The linux plugin has its own set of
# Linux desktop helpers; the two no longer mirror each other.)
[[ $OSTYPE == darwin* ]] || return 0

# cd into the folder shown in the frontmost Finder window
function cdf() {
  local dir
  dir=$(osascript -e 'tell application "Finder" to if (count of Finder windows) > 0 then return POSIX path of (target of front Finder window as alias)' 2>/dev/null)
  if [[ -z $dir ]]; then
    print -u2 "cdf: no Finder window with a folder is open"
    return 1
  fi
  cd -- "$dir"
}

# Open a man page as a PDF in Preview, e.g. `man-preview ls` or
# `man-preview 3 printf`. mandoc renders the PDF directly: Preview no longer
# opens the PostScript that `man -t` produces (macOS 14+).
function man-preview() {
  local page
  page=$(man -w "$@" 2>/dev/null) || { man "$@"; return }
  local pdf="${TMPDIR:-/tmp}/man-preview-${(j:-:)@}.pdf"
  mandoc -T pdf "${page%%$'\n'*}" >| "$pdf" && open -a Preview "$pdf"
}
compdef _man man-preview
