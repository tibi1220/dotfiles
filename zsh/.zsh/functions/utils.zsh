#! /usr/bin/env zsh

# Source changes without opening a new terminal window
function reload() {
  exec zsh
}

# Function to source non cloned plugins
function zsh_source_custom() {
  local plugin
  for plugin in "$ZSH_CUSTOM_PLUGINS"/**/*.plugin.zsh(N); do
    source "$plugin"
  done
}

function zsh_add_plugin() {
  local repository=$1
  local plugin_name=${repository:t}
  local plugin_dir="$ZSH_PLUGINS/$plugin_name"
  local plugin_file="$plugin_dir/$plugin_name.plugin.zsh"

  if [[ ! -d $plugin_dir ]]; then
    command git clone --depth=1 "https://github.com/$repository.git" "$plugin_dir" || return
  fi

  if [[ -r $plugin_file ]]; then
    source "$plugin_file"
  else
    print -u2 "zsh: plugin entry point not found: $plugin_file"
  fi
}

function zsh_update_plugins() {
  local plugin_dir
  for plugin_dir in "$ZSH_PLUGINS"/*/.git(N); do
    command git -C "${plugin_dir:h}" pull --ff-only
  done
}

alias zsh-reload='reload'
alias zsh-update-plugins='zsh_update_plugins'

# Open files/URLs with the platform's default handler (macOS, Linux, WSL).
# Used by the custom plugins (ofd, quick-look, web-search, ...).
function open_command() {
  emulate -L zsh
  local -a open_cmd
  case $OSTYPE in
    darwin*) open_cmd=(open) ;;
    cygwin*) open_cmd=(cygstart) ;;
    linux*)
      if [[ $(uname -r) == *icrosoft* ]]; then
        open_cmd=(cmd.exe /c start "")
        [[ -e $1 ]] && { 1=$(wslpath -w "${1:a}") || return 1 }
      elif (( $+commands[xdg-open] )); then
        open_cmd=(xdg-open)
      elif (( $+commands[gio] )); then
        open_cmd=(gio open)
      else
        print -u2 "$0: install xdg-utils (xdg-open) to open files"
        return 1
      fi
      ;;
    *)
      print -u2 "$0: platform $OSTYPE not supported"
      return 1
      ;;
  esac

  if [[ $OSTYPE == darwin* ]]; then
    $open_cmd "$@" &>/dev/null
  else
    # Detach so closing the terminal doesn't kill the opened app.
    nohup $open_cmd "$@" &>/dev/null &!
  fi
}
