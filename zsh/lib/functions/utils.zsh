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

# Compile a cloned plugin's scripts to .zwc files, which zsh loads instead of
# parsing the scripts (zsh-syntax-highlighting starts ~3 ms faster). zsh
# only uses a .zwc while it is newer than its script, so a stale one after a
# `git pull` is ignored until this runs again. Tests are skipped.
function _zsh_compile_plugin() {
  setopt local_options extended_glob
  local file
  for file in $1/**/*.zsh~*/(test|tests|test-data|spec)/*(N.); do
    [[ $file.zwc -nt $file ]] || zcompile $file 2>/dev/null
  done
}

function zsh_add_plugin() {
  local repository=$1
  local plugin_name=${repository:t}
  local plugin_dir="$ZSH_PLUGINS/$plugin_name"
  local plugin_file="$plugin_dir/$plugin_name.plugin.zsh"

  if [[ ! -d $plugin_dir ]]; then
    command git clone --depth=1 "https://github.com/$repository.git" "$plugin_dir" || return
    _zsh_compile_plugin $plugin_dir
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
    _zsh_compile_plugin ${plugin_dir:h}
  done
}

alias zsh-reload='reload'
alias zsh-update-plugins='zsh_update_plugins'
