#!/usr/bin/env zsh

# ------------------------------------------------------------------------------
# (Adapted from OMZ)
# (https://github.com/ohmyzsh/ohmyzsh/)
# ------------------------------------------------------------------------------

# Define clipcopy/clippaste for the current platform:
#   macOS            pbcopy / pbpaste
#   Wayland          wl-copy / wl-paste       (wl-clipboard)
#   X11              xclip or xsel
#   WSL              clip.exe / powershell.exe
#   tmux             tmux buffer (also forwarded to the terminal via OSC 52)
#   anything else    OSC 52 escape sequence (works over SSH, e.g. a headless
#                    Raspberry Pi, if the local terminal allows clipboard access)
function detect-clipboard() {
  emulate -L zsh

  if [[ $OSTYPE == darwin* ]] && (( $+commands[pbcopy] && $+commands[pbpaste] )); then
    function clipcopy() { cat "${1:-/dev/stdin}" | pbcopy; }
    function clippaste() { pbpaste; }
  elif [[ -n $WAYLAND_DISPLAY ]] && (( $+commands[wl-copy] && $+commands[wl-paste] )); then
    function clipcopy() { cat "${1:-/dev/stdin}" | wl-copy &>/dev/null &|; }
    function clippaste() { wl-paste --no-newline; }
  elif [[ -n $DISPLAY ]] && (( $+commands[xclip] )); then
    function clipcopy() { cat "${1:-/dev/stdin}" | xclip -selection clipboard -in &>/dev/null &|; }
    function clippaste() { xclip -out -selection clipboard; }
  elif [[ -n $DISPLAY ]] && (( $+commands[xsel] )); then
    function clipcopy() { cat "${1:-/dev/stdin}" | xsel --clipboard --input; }
    function clippaste() { xsel --clipboard --output; }
  elif (( $+commands[clip.exe] && $+commands[powershell.exe] )); then
    function clipcopy() { cat "${1:-/dev/stdin}" | clip.exe; }
    function clippaste() { powershell.exe -noprofile -command Get-Clipboard | tr -d '\r'; }
  elif [[ -n $TMUX ]]; then
    # -w also sets the outer terminal's clipboard (tmux >= 3.2, set-clipboard on).
    function clipcopy() { cat "${1:-/dev/stdin}" | tmux load-buffer -w -; }
    function clippaste() { tmux save-buffer -; }
  else
    function clipcopy() {
      printf '\e]52;c;%s\a' "$(base64 <"${1:-/dev/stdin}" | tr -d '\n')" >/dev/tty
    }
    function clippaste() {
      print -u2 "clippaste: no clipboard tool found (install wl-clipboard, xclip or xsel)"
      return 1
    }
  fi
}

# Re-run `detect-clipboard` after installing a clipboard tool.
detect-clipboard

# Copy the absolute path of the current directory
function copydir {
  emulate -L zsh
  print -n $PWD | clipcopy
}

# Copy the contents of a file
function copyfile {
  emulate -L zsh
  clipcopy $1
}

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
