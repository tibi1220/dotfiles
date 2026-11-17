#!/usr/bin/env bash
# The system part of the tmux status line (macOS): load average, memory in
# use and the battery. Colors turn yellow / red as each gets worse.
fg="#aeafb0" dim="#71839b" yellow="#dbc074" red="#c94f6d" green="#81b29a"

level() { # value warn crit -> color
  awk -v v="$1" -v w="$2" -v c="$3" -v fg="$fg" -v y="$yellow" -v r="$red" \
    'BEGIN { print (v >= c ? r : v >= w ? y : fg) }'
}

# 1-minute load average, as a share of the CPU cores
cores=$(sysctl -n hw.ncpu)
load=$(sysctl -n vm.loadavg | awk '{ print $2 }')
printf '#[fg=%s] #[fg=%s]%s ' "$dim" "$(level "$load" "$cores" "$((cores * 2))")" "$load"

# Memory in use (100 - what macOS calls free, which counts reclaimable memory)
free=$(memory_pressure -Q 2>/dev/null | awk -F': ' '/percentage/ { print $2 + 0 }')
if [[ -n $free ]]; then
  used=$((100 - free))
  printf '#[fg=%s] #[fg=%s]%s%% ' "$dim" "$(level "$used" 75 90)" "$used"
fi

# Battery, if there is one
batt=$(pmset -g batt 2>/dev/null | grep -o '[0-9]*%; [a-z ]*' | head -1)
if [[ -n $batt ]]; then
  pct=${batt%%%*}
  if [[ $batt == *discharging* ]]; then
    icons=(󰂎 󰁺 󰁻 󰁼 󰁽 󰁾 󰁿 󰂀 󰂁 󰂂 󰁹)
    icon=${icons[pct / 10]}
    color=$(level $((100 - pct)) 80 90)
  else
    icon=󰂄 color=$green
  fi
  printf '#[fg=%s]%s #[fg=%s]%s%% ' "$color" "$icon" "$color" "$pct"
fi
