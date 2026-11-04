#!/usr/bin/env zsh

# ------------------------------------------------------------------------------
# Linux (Ubuntu, Arch, Raspberry Pi OS) counterparts of the macos plugin.
# Finder/Xcode-specific commands (pfd, pfs, cdf, pushdf, pxd, cdx) and
# freespace (diskutil) have no Linux equivalent and are not defined here.
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

# Don't shadow a real vncviewer (e.g. TigerVNC) if installed
if (( ! $+commands[vncviewer] )); then
  function vncviewer() {
    open_command "vnc://$1"
  }
fi

# Remove .DS_Store files recursively in a directory, default .
function rmdsstore() {
  find "${@:-.}" -type f -name .DS_Store -delete
}

# Media player control via MPRIS (Spotify, browsers, mpv, ...), needs playerctl
function music() {
  emulate -L zsh
  if (( ! $+commands[playerctl] )); then
    print -u2 "$0: playerctl not found (apt/pacman install playerctl)"
    return 1
  fi

  local opt=$1
  (( $# > 0 )) && shift
  case $opt in
    play|pause|stop|next|previous)
      playerctl $opt
      ;;
    resume)
      playerctl play
      ;;
    playpause|toggle)
      playerctl play-pause
      ;;
    rewind)
      playerctl position 0
      ;;
    mute)
      playerctl volume 0
      ;;
    unmute)
      playerctl volume 0.5
      ;;
    vol)
      local volume
      volume=$(playerctl volume 2>/dev/null) || { print -u2 "No player running"; return 1 }
      volume=$(printf "%.0f" $(( volume * 100 )))
      case $1 in
        "") echo "Current volume is ${volume}."; return 0 ;;
        up) volume=$(( volume + 10 < 100 ? volume + 10 : 100 )) ;;
        down) volume=$(( volume - 10 > 0 ? volume - 10 : 0 )) ;;
        <0-100>) volume=$1 ;;
        *) echo "'$1' is not valid. Expected <0-100>, up or down."; return 1 ;;
      esac
      playerctl volume $(printf "%.2f" $(( volume / 100.0 )))
      ;;
    playing|status)
      local state=$(playerctl status 2>/dev/null)
      if [[ $state == Playing ]]; then
        autoload -Uz colors && colors
        echo -E "Listening to ${fg[yellow]}$(playerctl metadata title)${reset_color} by ${fg[yellow]}$(playerctl metadata artist)${reset_color}"
      else
        echo "Player is ${state:-not running}"
      fi
      ;;
    shuf|shuff|shuffle)
      case ${1:-toggle} in
        on) playerctl shuffle On ;;
        off) playerctl shuffle Off ;;
        toggle) playerctl shuffle Toggle ;;
        *) echo "'$1' is not valid. Expected on, off or toggle."; return 1 ;;
      esac
      ;;
    -h|--help|*)
      echo "Usage: $0 <option>"
      echo "option:"
      echo "\t-h|--help\tShow this message and exit"
      echo "\tplay|pause|playpause|stop|rewind|resume"
      echo "\tmute|unmute\tMute or unmute the player"
      echo "\tnext|previous\tPlay next or previous track"
      echo "\tshuf|shuffle [on|off|toggle]\tSet shuffled playback. Default: toggle."
      echo "\tvol [0-100|up|down]\tGet or set the volume."
      echo "\tplaying|status\tShow what is currently playing."
      [[ $opt == (-h|--help) ]]
      return
      ;;
  esac
}
