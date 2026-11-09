# Interactive setup shared by zsh and bash: aliases, fzf settings, functions.
# Sourced by zsh/.zsh/functions/functions.zsh and bash/.bashrc.

source "$SHELLDIR/aliases.sh"
source "$SHELLDIR/fzf.sh"

for _dotfiles_fn in "$SHELLDIR"/functions/*.sh; do
  source "$_dotfiles_fn"
done
unset _dotfiles_fn
