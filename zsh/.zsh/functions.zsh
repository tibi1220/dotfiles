#!/usr/bin/env zsh

# Source changes without opening a new terminal window
function reload() {
  exec zsh
}

alias zsh-reload='reload'

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

alias zsh-update-plugins='zsh_update_plugins'
