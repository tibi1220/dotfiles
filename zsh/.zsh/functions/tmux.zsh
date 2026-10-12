#! /usr/bin/env zsh

# Show a session picker when tmux is started without arguments. All regular
# tmux commands are passed directly to the real executable.
function tmux() {
  if (( $# > 0 )) || [[ ! -o interactive ]]; then
    command tmux "$@"
    return $?
  fi

  if (( ! $+commands[fzf] )); then
    command tmux
    return $?
  fi

  local new_session_label='＋  Create a new session'
  local items choice action session_id session_name default_name

  items=$(command tmux list-sessions \
    -F $'session\t#{session_id}\t#{session_name}\t#{session_windows} windows\t#{?session_attached,attached,detached}' \
    2>/dev/null)

  choice=$(
    {
      print -r -- $'new\t\t'"$new_session_label"
      [[ -n $items ]] && print -r -- "$items"
    } | command fzf \
      --height='60%' \
      --layout=reverse \
      --border=rounded \
      --delimiter=$'\t' \
      --with-nth='3..' \
      --no-multi \
      --prompt='tmux  ' \
      --pointer='▶' \
      --header='Enter: open  •  Esc: cancel'
  ) || return 0

  action=${choice%%$'\t'*}

  if [[ $action == new ]]; then
    # Colons and periods are tmux target separators and cannot be used in a
    # session name. This also turns a directory like .config into "config".
    default_name=${${PWD:t}#.}
    default_name=${default_name//[.:]/-}
    [[ -z $default_name ]] && default_name=main
    read "session_name?New session name [$default_name]: "
    session_name=${session_name:-$default_name}
    [[ -z $session_name ]] && return 0

    if command tmux has-session -t "=$session_name" 2>/dev/null; then
      session_id=$session_name
    elif [[ -n ${TMUX:-} ]]; then
      command tmux new-session -d -s "$session_name" || return $?
      session_id=$session_name
    else
      command tmux new-session -s "$session_name"
      return $?
    fi
  else
    local remainder=${choice#*$'\t'}
    session_id=${remainder%%$'\t'*}
  fi

  if [[ -n ${TMUX:-} ]]; then
    command tmux switch-client -t "$session_id"
  else
    command tmux attach-session -t "$session_id"
  fi
}

alias t='tmux'
alias ta='tmux attach -t'
alias tn='tmux new-session -s'
alias tl='tmux ls'
alias tk='tmux kill-session -t'
alias tka='tmux kill-server'
