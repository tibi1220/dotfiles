# fzf settings shared by zsh and bash. The shell-specific key bindings are
# loaded by zsh/.zsh/fzf.zsh and bash/fzf.bash.

command -v fzf >/dev/null 2>&1 || return 0

# Use fd if available (it's called fdfind on Ubuntu/Raspberry Pi OS).
_fzf_fd=
if command -v fd >/dev/null 2>&1; then
  _fzf_fd=fd
elif command -v fdfind >/dev/null 2>&1; then
  _fzf_fd=fdfind
fi

if [[ -n $_fzf_fd ]]; then
  export FZF_DEFAULT_COMMAND="$_fzf_fd --type f --hidden --follow --exclude .git"
  export FZF_CTRL_T_COMMAND="$_fzf_fd --hidden --follow --exclude .git"
  export FZF_ALT_C_COMMAND="$_fzf_fd --type d --hidden --follow --exclude .git"
  # Used by **<Tab> completion
  eval "_fzf_compgen_path() { $_fzf_fd --hidden --follow --exclude .git . \"\$1\"; }"
  eval "_fzf_compgen_dir() { $_fzf_fd --type d --hidden --follow --exclude .git . \"\$1\"; }"
fi

export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --border"

# Previews: file contents for Ctrl-T, directory tree for Alt-C.
_fzf_cat='cat {}'
_fzf_tree='ls -A {}'
if command -v bat >/dev/null 2>&1; then
  _fzf_cat='bat --style=numbers --color=always --line-range=:300 {}'
elif command -v batcat >/dev/null 2>&1; then
  _fzf_cat='batcat --style=numbers --color=always --line-range=:300 {}'
fi
command -v eza >/dev/null 2>&1 && _fzf_tree='eza --tree --level=2 --icons --color=always {}'
export FZF_CTRL_T_OPTS="--preview '[[ -d {} ]] && $_fzf_tree || $_fzf_cat'"
export FZF_ALT_C_OPTS="--preview '$_fzf_tree'"

unset _fzf_fd _fzf_cat _fzf_tree
