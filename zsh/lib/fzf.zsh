#!/usr/bin/env zsh

# fzf: fuzzy finder. Only loaded if it is installed.
#   Ctrl-R   search command history
#   Ctrl-T   insert files/directories into the command line
#   Alt-C    cd into a subdirectory
#   **<Tab>  fuzzy completion (e.g. `nvim **<Tab>`, `cd **<Tab>`, `kill <Tab>`)
(( $+commands[fzf] )) || return 0

# FZF_* settings and previews are shared with bash: see $SHELLDIR/fzf.sh.

# fzf >= 0.48 ships its own zsh integration; older distro packages
# (e.g. Ubuntu 22.04, Raspberry Pi OS) ship separate scripts.
if fzf --zsh &>/dev/null; then
  source <(fzf --zsh)
else
  typeset _fzf_dir
  for _fzf_dir in /usr/share/doc/fzf/examples /usr/share/fzf /usr/share/fzf/shell; do
    [[ -r $_fzf_dir/key-bindings.zsh ]] || continue
    source $_fzf_dir/key-bindings.zsh
    [[ -r $_fzf_dir/completion.zsh ]] && source $_fzf_dir/completion.zsh
    break
  done
fi

unset _fzf_dir
