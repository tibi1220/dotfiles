# Open files/URLs with the platform's default handler (macOS, Linux, WSL).
# Used by ofd, quick-look, web-search, ...
open_command() {
  local -a cmd
  case $OSTYPE in
    darwin*) cmd=(open) ;;
    cygwin*) cmd=(cygstart) ;;
    linux*)
      if [[ $(uname -r) == *icrosoft* ]]; then
        cmd=(cmd.exe /c start "")
        if [[ -e $1 ]]; then
          local win
          win=$(wslpath -w "$(realpath "$1")") || return 1
          set -- "$win" "${@:2}"
        fi
      elif command -v xdg-open >/dev/null 2>&1; then
        cmd=(xdg-open)
      elif command -v gio >/dev/null 2>&1; then
        cmd=(gio open)
      else
        echo "open_command: install xdg-utils (xdg-open) to open files" >&2
        return 1
      fi
      ;;
    *)
      echo "open_command: platform $OSTYPE not supported" >&2
      return 1
      ;;
  esac

  if [[ $OSTYPE == darwin* ]]; then
    "${cmd[@]}" "$@" >/dev/null 2>&1
  else
    # Detach so closing the terminal doesn't kill the opened app.
    (nohup "${cmd[@]}" "$@" >/dev/null 2>&1 &)
  fi
}
