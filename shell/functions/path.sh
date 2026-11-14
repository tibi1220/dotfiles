# path: print $PATH one folder per line, numbered in the order the shell
# searches them (the first folder holding a command wins):
#    1  ~/.local/bin
#    2  /opt/homebrew/bin
#    9  /opt/homebrew/bin   repeat of 2     (dimmed: never searched again)
#   10  ~/old/bin           missing         (red: the folder doesn't exist)
# ~ stands for the home folder. Colors only when printing to a terminal.
# Shared by zsh and bash.
path() {
  local dim='' red='' num='' off=''
  if [ -t 1 ]; then
    dim=$'\033[2m' red=$'\033[31m' num=$'\033[34m' off=$'\033[0m'
  fi

  local n=0 width=${#PATH} seen='' dir shown note first entry i
  # Column width for the numbers
  width=$(printf '%s' "$PATH" | tr -cd ':' | wc -c)
  width=$((width + 1)) # arithmetic drops the spaces macOS wc pads with
  width=${#width}
  [ "$width" -lt 2 ] && width=2

  while IFS= read -r dir; do
    n=$((n + 1))
    shown=$dir
    case $dir in
      "$HOME") shown='~' ;;
      "$HOME"/*) shown="~${dir#"$HOME"}" ;;
    esac

    # An earlier copy of the same folder?
    first=''
    while IFS= read -r entry; do
      [ -z "$entry" ] && continue
      i=${entry%%:*}
      if [ "${entry#*:}" = "$dir" ]; then
        first=$i
        break
      fi
    done <<EOF
$seen
EOF
    seen="$seen$n:$dir
"

    if [ -z "$dir" ]; then
      note="${red}empty: means the current folder${off}"
      shown=''
    elif [ -n "$first" ]; then
      printf "%s%${width}d  %s  repeat of %s%s\n" "$dim" "$n" "$shown" "$first" "$off"
      continue
    elif [ ! -d "$dir" ]; then
      note="${red}missing${off}"
    else
      note=''
    fi
    printf "%s%${width}d%s  %s%s\n" "$num" "$n" "$off" "$shown" "${note:+  $note}"
  done <<EOF
$(printf '%s\n' "$PATH" | tr ':' '\n')
EOF
}
