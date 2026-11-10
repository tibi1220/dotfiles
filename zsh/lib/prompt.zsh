#!/usr/bin/env zsh

# Prompt:  [MAC:~/D/0/2/fedgs] (main ↑2↓1) ⟨mu⟩ took 42s [1] %
#   - user (%n) and host name (%m), then the working directory with parent directories
#     shortened to their first letter (".config" -> ".c")
#   - git branch, with ↑/↓ commits ahead of/behind its upstream, and status
#     letters when the tree is dirty:
#       a added  m modified  d deleted  r renamed  x conflict  u untracked
#   - how long the last command took, if it ran for 3 seconds or more
#   - the last exit code in red when it's non-zero
#   - % for a normal user, a bold # for root (cyan, magenta after an error)
#
# Everything is computed once per prompt in a precmd hook, with a single
# `git status` call; PS1 only reads the results.

autoload -Uz colors add-zsh-hook && colors
zmodload zsh/datetime # $EPOCHREALTIME
setopt prompt_subst

typeset -g _prompt_dir _prompt_git _prompt_duration _prompt_cmd_start

# Show the duration of commands that ran at least this many seconds
typeset -g PROMPT_DURATION_MIN=${PROMPT_DURATION_MIN:-3}

# Shorten $PWD: every parent directory to its first character (a leading dot
# is kept), the current directory in full. Named directories like ~ stay.
function _prompt_set_dir() {
  local p=${(%):-%~} out='' part
  if [[ $p != */* ]]; then
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
  [[ -n $ab ]] && ab="%{$fg[cyan]%} $ab"

  local out="%{$fg[green]%} (%{$fg[yellow]%}${ref//\%/%%}$ab"
  if (( $#lines == 1 )); then
    _prompt_git="$out%{$fg[green]%})%{$reset_color%}"
    return
  fi

  # Status letters, in this order: conflict, deleted, renamed, modified,
  # added, untracked.
  local -a changes=("${(@)lines[2,-1]}")
  local letters=''
  (( ${changes[(I)UU *]} )) && letters+="%{$fg[yellow]%}%Bx%b"
  (( ${changes[(I)( D|D ) *]} )) && letters+="%{$fg[red]%}%Bd%b"
  (( ${changes[(I)R  *]} )) && letters+="%{$fg[magenta]%}%Br%b"
  (( ${changes[(I)(MM|[ ]M|AM|[ ]T) *]} )) && letters+="%{$fg[yellow]%}%Bm%b"
  (( ${changes[(I)(A|M)  *]} )) && letters+="%{$fg[cyan]%}%Ba%b"
  (( ${changes[(I)\?\? *]} )) && letters+="%{$fg[green]%}%Bu%b"
  [[ -n $letters ]] && letters+="%{$fg[green]%}⟩"

  _prompt_git="$out%{$fg[green]%}) %{$fg[green]%}⟨%{$reset_color%}$letters"
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
  _prompt_duration="%{$fg[yellow]%} took $text"
}

function _prompt_precmd() {
  _prompt_set_duration
  _prompt_set_dir
  _prompt_set_git
}
add-zsh-hook preexec _prompt_preexec
add-zsh-hook precmd _prompt_precmd

PS1='%{${fg[green]}%}['
# PS1+=' %{${fg[blue]}%}%n'
# PS1+='%F{8}@%f'
PS1+='%{${fg[blue]}%}%m'
PS1+='%F{8}:%f'
PS1+='%{${fg[blue]}%}${_prompt_dir}'
PS1+='%{${fg[green]}%}]'
PS1+='%{${reset_color}%}${_prompt_git}${_prompt_duration}'
PS1+="%{$fg[green]%}%(?.. [%{$fg[red]%}%?%{$fg[green]%}]%{$fg[red]%})"
# % normally (green, or red after an error); as root, # in cyan, or magenta
# after an error
PS1+="%B %(!.%(?.%{$fg[cyan]%}.%{$fg[magenta]%})#.%%)%b"
# Reset so the typed command doesn't inherit the prompt's color
PS1+="%{$reset_color%} "
