# fzf key bindings and completion (if installed). FZF_* settings are shared
# with zsh: see $SHELLDIR/fzf.sh.
#   Ctrl-R   search command history
#   Ctrl-T   insert files/directories into the command line
#   Alt-C    cd into a subdirectory
#   **<Tab>  fuzzy completion (e.g. `nvim **<Tab>`, `cd **<Tab>`, `kill <Tab>`)
command -v fzf >/dev/null 2>&1 || return 0

# fzf >= 0.48 ships its own bash integration; older distro packages
# (e.g. Ubuntu 22.04, Raspberry Pi OS) ship separate scripts.
if fzf --bash >/dev/null 2>&1; then
  eval "$(fzf --bash)"
else
  for __fzf_dir in /usr/share/doc/fzf/examples /usr/share/fzf /usr/share/fzf/shell; do
    [[ -r $__fzf_dir/key-bindings.bash ]] || continue
    source "$__fzf_dir/key-bindings.bash"
    [[ -r $__fzf_dir/completion.bash ]] && source "$__fzf_dir/completion.bash"
    break
  done
  unset __fzf_dir
fi
