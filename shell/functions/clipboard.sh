# Clipboard helpers (adapted from OMZ's clipboard/copy plugins).
#
# detect-clipboard defines clipcopy/clippaste for the current platform:
#   macOS            pbcopy / pbpaste
#   Wayland          wl-copy / wl-paste       (wl-clipboard)
#   X11              xclip or xsel
#   WSL              clip.exe / powershell.exe
#   tmux             tmux buffer (also forwarded to the terminal via OSC 52)
#   anything else    OSC 52 escape sequence (works over SSH, e.g. a headless
#                    Raspberry Pi, if the local terminal allows clipboard access)
# Re-run it after installing a clipboard tool.

detect-clipboard() {
  _clip_has() { command -v "$1" >/dev/null 2>&1; }

  if [[ $OSTYPE == darwin* ]] && _clip_has pbcopy && _clip_has pbpaste; then
    clipcopy() { cat "${1:-/dev/stdin}" | pbcopy; }
    clippaste() { pbpaste; }
  elif [[ -n $WAYLAND_DISPLAY ]] && _clip_has wl-copy && _clip_has wl-paste; then
    clipcopy() { cat "${1:-/dev/stdin}" | wl-copy >/dev/null 2>&1; }
    clippaste() { wl-paste --no-newline; }
  elif [[ -n $DISPLAY ]] && _clip_has xclip; then
    clipcopy() { cat "${1:-/dev/stdin}" | xclip -selection clipboard -in >/dev/null 2>&1; }
    clippaste() { xclip -out -selection clipboard; }
  elif [[ -n $DISPLAY ]] && _clip_has xsel; then
    clipcopy() { cat "${1:-/dev/stdin}" | xsel --clipboard --input; }
    clippaste() { xsel --clipboard --output; }
  elif _clip_has clip.exe && _clip_has powershell.exe; then
    clipcopy() { cat "${1:-/dev/stdin}" | clip.exe; }
    clippaste() { powershell.exe -noprofile -command Get-Clipboard | tr -d '\r'; }
  elif [[ -n $TMUX ]]; then
    # -w also sets the outer terminal's clipboard (tmux >= 3.2, set-clipboard on).
    clipcopy() { cat "${1:-/dev/stdin}" | tmux load-buffer -w -; }
    clippaste() { tmux save-buffer -; }
  else
    clipcopy() {
      printf '\033]52;c;%s\a' "$(base64 <"${1:-/dev/stdin}" | tr -d '\n')" >/dev/tty
    }
    clippaste() {
      echo "clippaste: no clipboard tool found (install wl-clipboard, xclip or xsel)" >&2
      return 1
    }
  fi

  unset -f _clip_has
}

detect-clipboard

# Copy the absolute path of the current directory
copydir() {
  printf '%s' "$PWD" | clipcopy
}

# Copy the contents of a file
copyfile() {
  clipcopy "$1"
}
