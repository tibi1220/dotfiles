#!/usr/bin/env zsh

# Prompt:  [MAC:~/D/0/2/fedgs] (main ↑2↓1) ⟨mu⟩ took 42s [1] tibor %
#   - host name (%m), then the working directory with parent directories
#     shortened to their first letter (".config" -> ".c")
#   - three toggles, each a key and a command; the choice is saved and new
#     shells start with it:
#       Alt-P  togglepath   collapsed path / full path   (default: collapsed)
#       Alt-M  togglehost   show the host name           (default: shown)
#       Alt-N  toggleuser   show the user name before %  (default: hidden)
#   - git branch, with ↑/↓ commits ahead of/behind its upstream, and status
#     letters when the tree is dirty:
#       a added  m modified  d deleted  r renamed  x conflict  u untracked
#   - how long the last command took, if it ran for 3 seconds or more
#   - the last exit code in red when it's non-zero
#   - % for a normal user, a bold # for root (cyan, magenta after an error)
#
# Everything is computed once per prompt in a precmd hook, with a single
# `git status` call; PS1 only reads the results.

autoload -Uz add-zsh-hook
zmodload zsh/datetime # $EPOCHREALTIME
setopt prompt_subst

typeset -g _prompt_dir _prompt_git _prompt_duration _prompt_cmd_start
typeset -g _prompt_host _prompt_user

# Show the duration of commands that ran at least this many seconds
typeset -g PROMPT_DURATION_MIN=${PROMPT_DURATION_MIN:-3}

# ---------------------------------------------------------------------------
# Toggles (saved between shells)
# ---------------------------------------------------------------------------

# Each toggle is 0 or 1. These are the defaults, used when nothing is saved:
#   PROMPT_FULL_PATH  0: collapsed path (~/D/0/2/fedgs), 1: full path
#   PROMPT_SHOW_HOST  1: show the host name
#   PROMPT_SHOW_USER  0: hide the user name
typeset -gA _prompt_defaults=(
  PROMPT_FULL_PATH 0
  PROMPT_SHOW_HOST 1
  PROMPT_SHOW_USER 0
)

# Saved choices, one NAME=0/1 per line. Delete the file to reset.
typeset -g _prompt_state_file=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/prompt-state

# Set every toggle to its default, then apply the saved file. Only known
# names with a 0 or 1 value are accepted; anything else is ignored.
function _prompt_load_state() {
  local name line value
  for name in ${(k)_prompt_defaults}; do
    typeset -g $name=$_prompt_defaults[$name]
  done
  [[ -r $_prompt_state_file ]] || return
  for line in "${(@f)$(<$_prompt_state_file)}"; do
    name=${line%%=*} value=${line#*=}
    (( ${+_prompt_defaults[$name]} )) && [[ $value == [01] ]] &&
      typeset -g $name=$value
  done
}

# Write all toggles to the state file
function _prompt_save_state() {
  local name
  mkdir -p ${_prompt_state_file:h} 2>/dev/null
  for name in ${(ko)_prompt_defaults}; do
    print -r -- "$name=${(P)name}"
  done >| $_prompt_state_file
}

# Host and user parts of the prompt, rebuilt whenever a toggle changes
function _prompt_set_parts() {
  _prompt_host='' _prompt_user=''
  (( PROMPT_SHOW_HOST )) && _prompt_host="%F{blue}%m%F{8}:%f"
  # " " before the % or #, or " user" (green, cyan for root) right before it
  _prompt_user=' '
  (( PROMPT_SHOW_USER )) &&
    _prompt_user=" %(!.%F{cyan}.%F{green})%n"
}

# Flip one toggle ($1 is its name), save it and rebuild the prompt parts
function _prompt_toggle() {
  (( ${+_prompt_defaults[$1]} )) || return 1
  (( $1 = !$1 ))
  _prompt_save_state
  _prompt_set_parts
  _prompt_set_dir
}

# Commands; they take effect at the next prompt
function togglepath() { _prompt_toggle PROMPT_FULL_PATH }
function togglehost() { _prompt_toggle PROMPT_SHOW_HOST }
function toggleuser() { _prompt_toggle PROMPT_SHOW_USER }

# Keys; they redraw the prompt right away and keep the typed line
function _prompt_toggle_widget() {
  case $WIDGET in
    prompt-toggle-path) togglepath ;;
    prompt-toggle-host) togglehost ;;
    prompt-toggle-user) toggleuser ;;
  esac
  zle reset-prompt
}
zle -N prompt-toggle-path _prompt_toggle_widget
zle -N prompt-toggle-host _prompt_toggle_widget
zle -N prompt-toggle-user _prompt_toggle_widget
bindkey '^[p' prompt-toggle-path # Alt-P
bindkey '^[m' prompt-toggle-host # Alt-M
bindkey '^[n' prompt-toggle-user # Alt-N

# ---------------------------------------------------------------------------
# Prompt parts
# ---------------------------------------------------------------------------

# Shorten $PWD: every parent directory to its first character (a leading dot
# is kept), the current directory in full. Named directories like ~ stay.
# With PROMPT_FULL_PATH=1 the path is shown in full.
function _prompt_set_dir() {
  local p=${(%):-%~} out='' part
  if (( PROMPT_FULL_PATH )) || [[ $p != */* ]]; then
    out=$p
  else
    [[ $p == /* ]] && out=/
    for part in ${(s:/:)p:h}; do
      out+=${(M)part#(|.)[^.]}/
    done
    out+=${p:t}
  fi
  _prompt_dir=${out//\%/%%}
}

function _prompt_set_git() {
  _prompt_git=''
  local status_text
  status_text=$(GIT_OPTIONAL_LOCKS=0 command git status --porcelain -b --ignore-submodules=dirty 2>/dev/null) ||
    return

  local -a lines=("${(@f)status_text}")
  local header=${lines[1]#'## '} ref
  case $header in
    'No commits yet on '*) ref=${header#'No commits yet on '} ;;
    'HEAD (no branch)'*) ref=$(GIT_OPTIONAL_LOCKS=0 command git rev-parse --short HEAD 2>/dev/null) ;;
    *) ref=${${header%%...*}%% *} ;;
  esac

  # Commits ahead of/behind upstream, from the "[ahead 2, behind 1]" part of
  # the status header (branch names can't contain "[").
  local track='' ab=''
  [[ $header == *\[*\] ]] && track=${${header##*\[}%\]}
  [[ $track == *'ahead '* ]] && ab+="↑${${track#*ahead }%%,*}"
  [[ $track == *'behind '* ]] && ab+="↓${${track#*behind }%%,*}"
  [[ -n $ab ]] && ab="%F{cyan} $ab"

  local out="%F{green} (%F{yellow}${ref//\%/%%}$ab"
  if (( $#lines == 1 )); then
    _prompt_git="$out%F{green})%f"
    return
  fi

  # Status letters, in this order: conflict, deleted, renamed, modified,
  # added, untracked.
  local -a changes=("${(@)lines[2,-1]}")
  local letters=''
  (( ${changes[(I)UU *]} )) && letters+="%F{yellow}%Bx%b"
  (( ${changes[(I)( D|D ) *]} )) && letters+="%F{red}%Bd%b"
  (( ${changes[(I)R  *]} )) && letters+="%F{magenta}%Br%b"
  (( ${changes[(I)(MM|[ ]M|AM|[ ]T) *]} )) && letters+="%F{yellow}%Bm%b"
  (( ${changes[(I)(A|M)  *]} )) && letters+="%F{cyan}%Ba%b"
  (( ${changes[(I)\?\? *]} )) && letters+="%F{green}%Bu%b"
  [[ -n $letters ]] && letters+="%F{green}⟩"

  _prompt_git="$out%F{green}) ⟨%f$letters"
}

# Command duration: preexec stores the start time, precmd formats the
# elapsed time (42s, 3m 12s, 1h 5m) once the command has finished.
function _prompt_preexec() {
  _prompt_cmd_start=$EPOCHREALTIME
}

function _prompt_set_duration() {
  _prompt_duration=''
  [[ -n $_prompt_cmd_start ]] || return
  local -i secs=$(( EPOCHREALTIME - _prompt_cmd_start ))
  _prompt_cmd_start=''
  (( secs >= PROMPT_DURATION_MIN )) || return

  local text
  if (( secs < 60 )); then
    text="${secs}s"
  elif (( secs < 3600 )); then
    text="$(( secs / 60 ))m $(( secs % 60 ))s"
  else
    text="$(( secs / 3600 ))h $(( secs % 3600 / 60 ))m"
  fi
  _prompt_duration="%F{yellow} took $text"
}

function _prompt_precmd() {
  _prompt_set_duration
  _prompt_set_dir
  _prompt_set_git
}

add-zsh-hook preexec _prompt_preexec
add-zsh-hook precmd _prompt_precmd

_prompt_load_state
_prompt_set_parts

# ---------------------------------------------------------------------------
# PS1
# ---------------------------------------------------------------------------

PS1='%F{green}['
PS1+='${_prompt_host}' # "host:" when shown (Alt-M)
PS1+='%F{blue}${_prompt_dir}'
PS1+='%F{green}]'
PS1+='%f${_prompt_git}${_prompt_duration}'
PS1+='%F{green}%(?.. [%F{red}%?%F{green}])'
PS1+='${_prompt_user}' # " ", or " user" when shown (Alt-N)
PS1+='%B%(!.%(?.%F{cyan}.%F{magenta})#.%(?.%F{green}.%F{red})%%)%b'
PS1+='%f '
