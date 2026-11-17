#!/usr/bin/env bash
# The left part of the tmux status line after the session name: the current
# pane's folder and, in a git repository, its branch, how far it is
# ahead/behind its upstream and whether tracked files changed.
# Usage: pane-info.sh <path>   (tmux passes #{pane_current_path})
dir=${1:-$PWD}

fg="#aeafb0" dim="#71839b" green="#81b29a" yellow="#dbc074" magenta="#9d79d6"

# ~ for home, and only the last three folders of a long path
short=${dir/#$HOME/\~}
short=$(awk -F/ 'NF > 4 { $0 = "…/" $(NF-2) "/" $(NF-1) "/" $NF } 1' <<<"$short")
printf '#[fg=%s]  #[fg=%s]%s ' "$dim" "$fg" "$short"

# -uno: untracked files are skipped, which keeps this fast in big repos
status=$(git --no-optional-locks -C "$dir" status --porcelain=v2 --branch -uno 2>/dev/null) || exit 0
branch= ahead=0 behind=0 dirty=
while read -r a b c d; do
  case "$a $b" in
    "# branch.head") branch=$c ;;
    "# branch.oid") oid=${c:0:7} ;;
    "# branch.ab") ahead=${c#+} behind=${d#-} ;;
    "# "*) ;;
    *) dirty=1 ;;
  esac
done <<<"$status"
[[ $branch == "(detached)" ]] && branch=$oid

printf '#[fg=%s] #[fg=%s]%s' "$magenta" "$fg" "$branch"
((ahead > 0)) && printf ' #[fg=%s]↑%s' "$green" "$ahead"
((behind > 0)) && printf ' #[fg=%s]↓%s' "$yellow" "$behind"
[[ -n $dirty ]] && printf ' #[fg=%s]●' "$yellow"
printf ' '
