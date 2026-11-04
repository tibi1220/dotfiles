#!/usr/bin/env zsh

# fzf: fuzzy finder. Only loaded if it is installed.
#   Ctrl-R   search command history
#   Ctrl-T   insert files/directories into the command line
#   Alt-C    cd into a subdirectory
#   **<Tab>  fuzzy completion (e.g. `nvim **<Tab>`, `cd **<Tab>`, `kill <Tab>`)
(( $+commands[fzf] )) || return 0

# Use fd if available (it's called fdfind on Ubuntu/Raspberry Pi OS).
typeset _fzf_fd
if (( $+commands[fd] )); then
  _fzf_fd=fd
elif (( $+commands[fdfind] )); then
  _fzf_fd=fdfind
fi

if [[ -n $_fzf_fd ]]; then
  export FZF_DEFAULT_COMMAND="$_fzf_fd --type f --hidden --follow --exclude .git"
  export FZF_CTRL_T_COMMAND="$_fzf_fd --hidden --follow --exclude .git"
  export FZF_ALT_C_COMMAND="$_fzf_fd --type d --hidden --follow --exclude .git"
  # Used by **<Tab> completion
  eval "_fzf_compgen_path() { $_fzf_fd --hidden --follow --exclude .git . \"\$1\" }"
  eval "_fzf_compgen_dir() { $_fzf_fd --type d --hidden --follow --exclude .git . \"\$1\" }"
fi

export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --border"

# Previews: file contents for Ctrl-T, directory tree for Alt-C.
typeset _fzf_cat='cat {}' _fzf_tree='ls -A {}'
if (( $+commands[bat] )); then
  _fzf_cat='bat --style=numbers --color=always --line-range=:300 {}'
elif (( $+commands[batcat] )); then
  _fzf_cat='batcat --style=numbers --color=always --line-range=:300 {}'
fi
(( $+commands[eza] )) && _fzf_tree='eza --tree --level=2 --icons --color=always {}'
export FZF_CTRL_T_OPTS="--preview '[[ -d {} ]] && $_fzf_tree || $_fzf_cat'"
export FZF_ALT_C_OPTS="--preview '$_fzf_tree'"

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

unset _fzf_fd _fzf_cat _fzf_tree _fzf_dir
