#!/usr/bin/env zsh

# Shell options, completion and line-editor (ZLE) key bindings.
# Sourced from .zshrc before the prompt, functions and plugins.

# ---------------------------------------------------------------------------
# History
# ---------------------------------------------------------------------------

HISTFILE=$ZDOTDIR/.zsh_history
HISTSIZE=100000 # entries kept in memory
SAVEHIST=100000 # entries written to $HISTFILE

setopt extended_history     # save a timestamp and duration with each entry
setopt share_history        # write every command right away; all shells see it
setopt hist_ignore_all_dups # rerunning a command removes its older copy
setopt hist_find_no_dups    # Ctrl-R doesn't show the same command twice
setopt hist_save_no_dups    # don't write duplicates to $HISTFILE
setopt hist_ignore_space    # a command starting with a space is not saved
setopt hist_reduce_blanks   # "ls   -la" is saved as "ls -la"
setopt hist_verify          # !!, !$, ... expand onto the line instead of running

# ---------------------------------------------------------------------------
# General behaviour
# ---------------------------------------------------------------------------

setopt interactive_comments # allow "# comments" at the prompt

# ---------------------------------------------------------------------------
# Directories
# ---------------------------------------------------------------------------

setopt auto_cd           # type a directory name to cd into it
setopt auto_pushd        # every cd pushes the old directory on the stack:
                         #   dirs -v lists it, cd -2 / cd -<Tab> jumps back
setopt pushd_ignore_dups # each directory appears on the stack only once
setopt pushd_silent      # don't print the stack after every cd

# ---------------------------------------------------------------------------
# Completion
# ---------------------------------------------------------------------------

zmodload zsh/complist # menu selection and colored lists

# Tab opens a menu of matches; move through it with Tab or the arrow keys
zstyle ':completion:*' menu select

# Matching rules, tried in order until one finds something:
#   1. exact match
#   2. ignore case                  doc  -> Documents
#   3. complete around . _ -        f.b  -> foo.bar
#   4. match anywhere in the word   bar  -> foobar
zstyle ':completion:*' matcher-list \
  '' \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=*' \
  'l:|=* r:|=*'

# Color files like ls (zsh's default colors when LS_COLORS is unset)
zstyle ':completion:*' list-colors "${(@s.:.)LS_COLORS}"

# Group matches by kind, under a "-- command --" style header
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'

# Cache slow completions (brew install <Tab>, ...)
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# Start the completion system. The full check (every completion file, plus a
# security audit of their folders) runs at most once a day; otherwise the
# saved .zcompdump is loaded as is (-C). The glob qualifier (N.mh+24) matches
# the dump only if it is older than 24 hours, or missing (N: no error).
# compinit rewrites the dump only when something changed, so touch it after a
# full check; otherwise it would stay old and the check would run every time.
autoload -Uz compinit
() {
  local dump=$ZDOTDIR/.zcompdump
  local -a stale=($dump(N.mh+24))
  if (( $#stale )) || [[ ! -e $dump ]]; then
    compinit -d $dump
    touch $dump
  else
    compinit -C -d $dump
  fi
}

_comp_options+=(globdots) # complete hidden files without typing the dot

# ---------------------------------------------------------------------------
# Line editor (ZLE)
# ---------------------------------------------------------------------------

# Emacs-style keys (Ctrl-A/E, Ctrl-W, Alt-B/F, ...). Without this, zsh picks
# vi mode because $EDITOR is nvim. Useful built-ins this gives you:
#   Alt-Q    park the current line, run something else, get it back
#   Alt-.    insert the last argument of the previous command
#   Ctrl-_   undo
bindkey -e

# Treat / as a word separator, so Ctrl-W and Alt-Backspace delete one path
# component at a time: ~/dotfiles/zsh/lib -> ~/dotfiles/zsh/
WORDCHARS=${WORDCHARS//\/}

# Up/Down: with text typed, only cycle through commands starting with it.
# Each key is bound twice because terminals send either ^[[A or ^[OA.
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search

# Shift-Tab: go back in the completion menu
bindkey -M menuselect '^[[Z' reverse-menu-complete

# Alt-E: edit the command line in $EDITOR (nvim); save and quit to return
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^[e' edit-command-line

# Ctrl-Z on an empty line resumes the last suspended job, so Ctrl-Z toggles
# between nvim and the shell. With text typed, the line is parked instead
# (like Alt-Q) and comes back after the next command.
function _fg_or_park() {
  if [[ -z $BUFFER ]]; then
    BUFFER=fg
    zle accept-line
  else
    zle push-input
  fi
}
zle -N _fg_or_park
bindkey '^Z' _fg_or_park

# ---------------------------------------------------------------------------
# Extra commands
# ---------------------------------------------------------------------------

# zmv: rename files by pattern, e.g.  zmv -n '(*).jpeg' '$1.jpg'
# (-n shows what would happen without renaming)
autoload -Uz zmv
