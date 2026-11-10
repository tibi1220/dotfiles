#!/usr/bin/env zsh

# ------------------------------------------------------------------------------
# Linux (Ubuntu, Arch, Raspberry Pi OS) desktop helpers: open the file
# manager, show/hide hidden files, restart Bluetooth, tmux tabs/splits,
# quick-look and man-preview. The macos plugin has its own, smaller set.
# ------------------------------------------------------------------------------

[[ $OSTYPE == linux* ]] || return 0

# Open the current directory in the file manager
alias ofd='open_command $PWD'

# Show/hide hidden files in the file manager (GNOME/GTK)
function _linux_set_hidden_files() {
  emulate -L zsh
  if (( ! $+commands[gsettings] )); then
    print -u2 "gsettings not found (only GNOME/GTK file managers are supported)"
    return 1
  fi
  local schema ok=0
  for schema in org.gtk.gtk4.Settings.FileChooser org.gtk.Settings.FileChooser; do
    gsettings set $schema show-hidden $1 2>/dev/null && ok=1
  done
  (( ok )) || { print -u2 "No GTK file chooser settings schema found"; return 1 }
}
alias showfiles='_linux_set_hidden_files true'
alias hidefiles='_linux_set_hidden_files false'

# Bluetooth restart
function btrestart() {
  sudo systemctl restart bluetooth
}

# New tab / split in the current directory, optionally running a command.
# Uses tmux (the terminal emulator can't be scripted portably on Linux).
function _linux_tmux_open() {
  local name=$1 subcmd=$2
  shift 2
  if [[ -z $TMUX ]]; then
    print -u2 "$name: only supported inside tmux on Linux"
    return 1
  fi
  local pane
  pane=$(tmux ${=subcmd} -P -F '#{pane_id}' -c "$PWD") || return
  if (( $# )); then
    tmux send-keys -t "$pane" -l "$*" \; send-keys -t "$pane" Enter
  fi
}
function tab()        { _linux_tmux_open $0 new-window "$@" }
function split_tab()  { _linux_tmux_open $0 "split-window -v" "$@" }
function vsplit_tab() { _linux_tmux_open $0 "split-window -h" "$@" }

# Preview files with the default application
function quick-look() {
  local f
  for f in "$@"; do
    open_command "$f"
  done
}

# Open a man page as PDF (needs groff with the pdf device; falls back to man)
function man-preview() {
  man -w "$@" &>/dev/null || { man "$@"; return }
  local pdf="${TMPDIR:-/tmp}/man-preview-${(j:-:)@}.pdf"
  if man -Tpdf "$@" >| "$pdf" 2>/dev/null && [[ -s $pdf ]]; then
    open_command "$pdf"
  else
    man "$@"
  fi
}
compdef _man man-preview
