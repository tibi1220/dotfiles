#!/usr/bin/env zsh

# Prompt:  [tiborsandor@MAC:~/D/0/2/fedgs] (main) ⟨mu⟩ [1] %
#   - user (%n) and host name (%m), then the working directory with parent directories
#     shortened to their first letter (".config" -> ".c")
#   - git branch, with status letters when the tree is dirty:
#       a added  m modified  d deleted  r renamed  x conflict  u untracked
#   - the last exit code in red when it's non-zero
#   - % for a normal user, # for root (%#)
#
# Everything is computed once per prompt in a precmd hook, with a single
# `git status` call; PS1 only reads the results.

autoload -Uz colors add-zsh-hook && colors
setopt prompt_subst

typeset -g _prompt_dir _prompt_git

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

  local out="%{$fg[green]%} (%{$fg[yellow]%}${ref//\%/%%}"
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

function _prompt_precmd() {
  _prompt_set_dir
  _prompt_set_git
}
add-zsh-hook precmd _prompt_precmd

PS1='%{${fg[green]}%}['
# PS1+=' %{${fg[blue]}%}%n'
# PS1+='%F{8}@%f'
PS1+='%{${fg[blue]}%}%m'
PS1+='%F{8}:%f'
PS1+='%{${fg[blue]}%}${_prompt_dir}'
PS1+='%{${fg[green]}%}]'
PS1+='%{${reset_color}%}${_prompt_git}'
PS1+="%{$fg[green]%}%(?.. [%{$fg[red]%}%?%{$fg[green]%}]%{$fg[red]%})%B %#%b "
