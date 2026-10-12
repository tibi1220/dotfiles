#! /usr/bin/env zsh

# Package manager
if [[ $(uname) == "Darwin" ]]; then
  alias bup="brew update && brew upgrade"
  alias bslist="brew services list"
  alias bsstart="brew services start"
  alias bsstop="brew services stop"
  # TODO: Add commands and checks for arch linux
fi
