#!/bin/sh
# Link this repository's configs into place.
#
#   ./install.sh            link everything that isn't set up yet
#   ./install.sh --force    also replace existing files and folders
#   ./install.sh --dry-run  only show what would be done
#
# Each config folder is linked into ~/.config, and a few files that programs
# look for elsewhere are linked from there (~/.zshenv, ~/.bashrc, ...).
# Links that are already correct are left alone, so the script can be run
# again at any time, e.g. after adding a new folder.
#
# Without --force, anything already in the way is skipped and reported.
# With --force it is moved aside as <name>.backup (or
# <name>.backup.<date-time> if that exists too) and replaced by the link;
# nothing is deleted.

set -eu

# Folders linked as ~/.config/<name>
CONFIGS="bash bat btop fastfetch kitty lazygit nvim tmux zsh"

force=0
dry_run=0
for arg in "$@"; do
  case $arg in
    -f | --force) force=1 ;;
    -n | --dry-run) dry_run=1 ;;
    -h | --help)
      sed -n '2,/^$/s/^# \{0,1\}//p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg (see --help)" >&2
      exit 2
      ;;
  esac
done

# The repository is wherever this script is, not necessarily ~/dotfiles
DOTFILES=$(cd "$(dirname "$0")" && pwd -P)
CONFIG_HOME="$HOME/.config"

linked=0 ok=0 skipped=0 replaced=0

if [ -t 1 ]; then
  green=$(printf '\033[32m') yellow=$(printf '\033[33m')
  blue=$(printf '\033[34m') reset=$(printf '\033[0m')
else
  green='' yellow='' blue='' reset=''
fi

# Print a path with $HOME shortened to ~
short() {
  case $1 in
    "$HOME"/*) printf '~%s' "${1#"$HOME"}" ;;
    *) printf '%s' "$1" ;;
  esac
}

run() {
  if [ "$dry_run" -eq 1 ]; then
    return 0
  fi
  "$@"
}

# link <source> <target>: make <target> a symlink to <source>
link() {
  src=$1 target=$2

  if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
    printf '  %sok%s       %s\n' "$green" "$reset" "$(short "$target")"
    ok=$((ok + 1))
    return
  fi

  if [ -e "$target" ] || [ -L "$target" ]; then
    if [ "$force" -eq 0 ]; then
      printf '  %sskipped%s  %s (already exists; --force replaces it)\n' \
        "$yellow" "$reset" "$(short "$target")"
      skipped=$((skipped + 1))
      return
    fi
    backup="$target.backup"
    if [ -e "$backup" ] || [ -L "$backup" ]; then
      backup="$target.backup.$(date +%Y%m%d-%H%M%S)"
    fi
    run mv "$target" "$backup"
    printf '  %sreplaced%s %s (old one moved to %s)\n' \
      "$blue" "$reset" "$(short "$target")" "$(short "$backup")"
    replaced=$((replaced + 1))
  else
    printf '  %slinked%s   %s\n' "$green" "$reset" "$(short "$target")"
    linked=$((linked + 1))
  fi

  run mkdir -p "$(dirname "$target")"
  run ln -s "$src" "$target"
}

[ "$dry_run" -eq 1 ] && echo "Dry run: nothing will be changed."
echo "Linking $(short "$DOTFILES")"

echo "~/.config:"
for name in $CONFIGS; do
  link "$DOTFILES/$name" "$CONFIG_HOME/$name"
done

echo "Home folder:"
# zsh: .zshenv sets ZDOTDIR so zsh finds the rest in ~/.config/zsh
link "$CONFIG_HOME/zsh/.zshenv" "$HOME/.zshenv"
# bash reads these directly
link "$CONFIG_HOME/bash/.bashrc" "$HOME/.bashrc"
link "$CONFIG_HOME/bash/.bash_profile" "$HOME/.bash_profile"

# On macOS lazygit reads ~/Library/Application Support/lazygit instead of
# ~/.config/lazygit. Only the config file is linked: lazygit keeps its own
# state files in that folder.
if [ "$(uname -s)" = Darwin ]; then
  echo "macOS:"
  link "$CONFIG_HOME/lazygit/config.yml" \
    "$HOME/Library/Application Support/lazygit/config.yml"
fi

# bat loads themes from a cache, which has to be rebuilt to find Nightfox
bat=''
if command -v bat >/dev/null 2>&1; then
  bat=bat
elif command -v batcat >/dev/null 2>&1; then
  bat=batcat # Ubuntu, Raspberry Pi OS
fi
if [ -n "$bat" ]; then
  echo "bat:"
  if [ "$dry_run" -eq 1 ]; then
    echo "  would run: $bat cache --build"
  elif "$bat" cache --build >/dev/null 2>&1; then
    printf '  %sok%s       theme cache rebuilt\n' "$green" "$reset"
  else
    printf '  %sfailed%s   %s cache --build\n' "$yellow" "$reset" "$bat"
  fi
fi

echo
echo "Done: $linked linked, $ok already ok, $replaced replaced, $skipped skipped."
if [ "$skipped" -gt 0 ]; then
  echo "Skipped paths were left untouched. Run again with --force to replace them"
  echo "(they are moved aside as *.backup, not deleted)."
fi
if [ "$dry_run" -eq 0 ] && [ $((linked + replaced)) -gt 0 ]; then
  echo "Open a new shell (or run: exec zsh -l) to load the new configs."
fi
