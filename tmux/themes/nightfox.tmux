#!/usr/bin/env bash
# Nightfox colors for Tmux
# Style: nightfox
# Colors from: https://github.com/edeneast/nightfox.nvim/raw/main/extra/nightfox/nightfox.tmux (the status line is our own)
set -g mode-style "fg=#131a24,bg=#aeafb0"
set -g message-style "fg=#131a24,bg=#aeafb0"
set -g message-command-style "fg=#131a24,bg=#aeafb0"
set -g pane-border-style "fg=#aeafb0"
set -g pane-active-border-style "fg=#719cd6"
set -g popup-style "default"
set -g popup-border-style "fg=#719cd6"

# Status line, along the top:
#   left:   session (blue text; yellow after the prefix key, purple in copy
#           mode, red with synchronized panes), the pane's folder and git
#           branch (scripts/pane-info.sh)
#   center: windows (󰊓 zoomed pane, 󰂚 bell, ● activity)
#   right:  load, memory, battery (scripts/system-info.sh), date and time,
#           host
set -g status "on"
set -g status-position "top"
set -g status-interval 5
set -g status-justify "absolute-centre"
set -g status-style "fg=#aeafb0,bg=default"
set -g status-left-length "100"
set -g status-right-length "100"
set -g status-left-style NONE
set -g status-right-style NONE
set -g @status_accent "#{?client_prefix,#dbc074,#{?pane_in_mode,#9d79d6,#{?pane_synchronized,#c94f6d,#719cd6}}}"
set -g status-left "#[fg=#{E:@status_accent},bold]  #S #[fg=#71839b,nobold]│#[default]#(~/.config/tmux/scripts/pane-info.sh '#{pane_current_path}')"
set -g status-right "#(~/.config/tmux/scripts/system-info.sh)#[fg=#71839b]│ #[fg=#aeafb0]%a %b %-d #[fg=#71839b]│ #[fg=#aeafb0,bold]%H:%M #[fg=#71839b,nobold]│ #[fg=#{E:@status_accent},bold] 󰍹 #h "
setw -g window-status-activity-style "fg=#71839b,bg=default"
setw -g window-status-bell-style "fg=#c94f6d,bg=default"
setw -g window-status-separator ""
setw -g window-status-format "#[default] #I #W#{?window_zoomed_flag, 󰊓,}#{?window_bell_flag, 󰂚,}#{?window_activity_flag, ●,} "
setw -g window-status-current-format "#[fg=#719cd6,bold] #I #W#{?window_zoomed_flag, 󰊓,} "
