# shell

Configuration shared by zsh and bash. Files here must use syntax that works in
both shells (bash 4+ and zsh): no zsh-only expansions or `setopt`, no
bash-only `shopt`/`bind`.

| File | Loaded from | Contents |
| --- | --- | --- |
| `dirs.sh` | every shell | Directory variables (`CODEDIR`, `DOTFILESDIR`, …) |
| `env.sh` | login and interactive shells | PATH, Homebrew, pnpm, editor, `NVIM_PROFILE` |
| `init.sh` | interactive shells | Sources `aliases.sh`, `fzf.sh` and `functions/*.sh` |
