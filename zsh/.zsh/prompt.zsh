#!/usr/bin/env zsh

autoload -Uz add-zsh-hook colors
colors
setopt prompt_subst

shpwd() {
  if [[ $PWD == $HOME ]]; then
    print -r -- "~"
  else
    local short_path="${${:-/${(j:/:)${(M)${(s:/:)${(D)PWD:h}}#(|.)[^.]}}/${PWD:t}}//\/~/\~}"
    print -r -- "${short_path#//}"
  fi
}

# Build all Git prompt information from a single status invocation before each
# prompt. This avoids repeatedly scanning large repositories during rendering.
typeset -g GIT_PROMPT=''

update_git_prompt() {
  emulate -L zsh

  local output line branch oid xy
  local -a counts
  local -A states
  local -i ahead=0 behind=0

  output=$(GIT_OPTIONAL_LOCKS=0 command git status --porcelain=v2 --branch 2>/dev/null) || {
    GIT_PROMPT=''
    return
  }

  for line in ${(f)output}; do
    case $line in
      '# branch.head '*)
        branch=${line[15,-1]}
        ;;
      '# branch.oid '*)
        oid=${line[14,-1]}
        ;;
      '# branch.ab '*)
        counts=(${=line[13,-1]})
        ahead=${counts[1]#+}
        behind=${counts[2]#-}
        ;;
      '1 '*|'2 '*)
        xy=${line[3,4]}
        case ${xy[1]} in
          A|C) states[added]=1 ;;
          M|T) states[modified]=1 ;;
          R) states[renamed]=1 ;;
          D) states[deleted]=1 ;;
          U) states[unmerged]=1 ;;
        esac
        case ${xy[2]} in
          A|C) states[added]=1 ;;
          M|T) states[modified]=1 ;;
          R) states[renamed]=1 ;;
          D) states[deleted]=1 ;;
          U) states[unmerged]=1 ;;
        esac
        ;;
      'u '*) states[unmerged]=1 ;;
      '? '*) states[untracked]=1 ;;
    esac
  done

  [[ $branch == '(detached)' ]] && branch=${oid[1,7]}
  branch=${branch//\%/%%}

  local markers=''
  [[ -n ${states[untracked]} ]] && markers+='%F{green}%Bu%b'
  [[ -n ${states[added]} ]] && markers+='%F{cyan}%Ba%b'
  [[ -n ${states[modified]} ]] && markers+='%F{yellow}%Bm%b'
  [[ -n ${states[renamed]} ]] && markers+='%F{magenta}%Br%b'
  [[ -n ${states[deleted]} ]] && markers+='%F{red}%Bd%b'
  [[ -n ${states[unmerged]} ]] && markers+='%F{yellow}%Bx%b'
  (( ahead > 0 )) && markers+="%F{cyan}↑${ahead}"
  (( behind > 0 )) && markers+="%F{magenta}↓${behind}"

  GIT_PROMPT="%F{green} (%F{yellow}${branch}%F{green})"
  [[ -n $markers ]] && GIT_PROMPT+=" ⟨${markers}%F{green}⟩"
  GIT_PROMPT+='%f'
}

add-zsh-hook precmd update_git_prompt

PROMPT='%F{green}[%F{blue}$(shpwd)%F{green}]${GIT_PROMPT}%f'
PROMPT+='%F{green}%(?.. [%F{red}%?%F{green}]%F{red})%B ➜%b '
