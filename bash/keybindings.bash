# Readline behaviour, closer to the zsh setup.

# Tab completion: case-insensitive, list all matches at once, then cycle
# through them with Tab / Shift-Tab (like zsh's menu select).
bind 'set completion-ignore-case on'
bind 'set completion-map-case on'
bind 'set show-all-if-ambiguous on'
bind 'set menu-complete-display-prefix on'
bind 'set colored-stats on'
bind 'set colored-completion-prefix on'
bind 'set visible-stats on'
bind 'set mark-symlinked-directories on'
bind 'set skip-completed-text on'
bind 'TAB: menu-complete'
bind '"\e[Z": menu-complete-backward'

# Up/Down search history for lines starting with what's already typed
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
bind '"\eOA": history-search-backward'
bind '"\eOB": history-search-forward'

# Ctrl-O: copy the current command line to the clipboard
__copybuffer() {
  printf '%s' "$READLINE_LINE" | clipcopy
}
bind -x '"\C-o": __copybuffer'

# Esc Esc: add or remove "sudo " at the start of the line. On an empty line,
# use the previous command (like the zsh sudo plugin).
__sudo_toggle() {
  if [[ -z $READLINE_LINE ]]; then
    # Inside bind -x, $(fc -ln -1) and $(history -p !!) return the command
    # before the last one; $(history 1) does not.
    local last
    last=$(HISTTIMEFORMAT='' history 1)
    [[ $last =~ ^[[:space:]]*[0-9]+\*?[[:space:]]+(.*)$ ]] && last=${BASH_REMATCH[1]}
    READLINE_LINE=$last
    READLINE_POINT=${#READLINE_LINE}
  fi
  if [[ $READLINE_LINE == "sudo "* ]]; then
    READLINE_LINE=${READLINE_LINE#sudo }
    READLINE_POINT=$(( READLINE_POINT > 5 ? READLINE_POINT - 5 : 0 ))
  else
    READLINE_LINE="sudo $READLINE_LINE"
    READLINE_POINT=$(( READLINE_POINT + 5 ))
  fi
}
bind -x '"\e\e": __sudo_toggle'
