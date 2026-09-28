#!/usr/bin/env bash
# Nightfox colors for Tmux
# Style: nightfox
# Upstream: https://github.com/edeneast/nightfox.nvim/raw/main/extra/nightfox/nightfox.tmux
set -g mode-style "fg=#131a24,bg=#aeafb0"
set -g message-style "fg=#131a24,bg=#aeafb0"
set -g message-command-style "fg=#131a24,bg=#aeafb0"
set -g pane-border-style "fg=#aeafb0"
set -g pane-active-border-style "fg=#719cd6"
set -g status "on"
set -g status-position "bottom"
set -g status-justify "absolute-centre"
set -g status-style "fg=#aeafb0,bg=#131a24"
set -g status-left-length "200"
set -g status-right-length "200"
set -g status-left-style NONE
set -g status-right-style NONE
set -g @nvim_mode_fg "#131a24"
set -g @nvim_mode_bg "#719cd6"
set -g status-left '#[fg=#{?#{m/r:^(n?vim)(diff)?$,#{pane_current_command}},#{@nvim_mode_fg},#131a24},bg=#{?#{m/r:^(n?vim)(diff)?$,#{pane_current_command}},#{@nvim_mode_bg},#719cd6},bold] #S #[default]#(cat #{socket_path}-\#{session_id}-vimbridge)'
set -g status-right '#(cat #{socket_path}-\#{session_id}-vimbridge-R)#[fg=#719cd6,bg=#131a24]#{prefix_highlight}#[fg=#131a24,bg=#aeafb0] %Y-%m-%d  %I:%M %p #[fg=#{?#{m/r:^(n?vim)(diff)?$,#{pane_current_command}},#{@nvim_mode_fg},#131a24},bg=#{?#{m/r:^(n?vim)(diff)?$,#{pane_current_command}},#{@nvim_mode_bg},#719cd6},bold] #h '
setw -g window-status-activity-style "underscore,fg=#71839b,bg=#131a24"
setw -g window-status-separator ""
setw -g window-status-style "NONE,fg=#71839b,bg=#131a24"
setw -g window-status-format "#[default] #I #W #F "
setw -g window-status-current-format "#[fg=#131a24,bg=#aeafb0,bold] #I #W #F "
