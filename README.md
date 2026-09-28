# macOS dotfiles

Personal macOS configuration for Kitty, Neofetch, Neovim, tmux, and Zsh. The
repository keeps application configuration together while excluding caches,
shell history, downloaded plugins, and macOS metadata.

## Included configuration

| Directory | Purpose |
| --- | --- |
| `kitty/` | Terminal font, window, symbol, bell, and color settings |
| `neofetch/` | System-information layout and appearance |
| `nvim/` | Lua-based Neovim setup managed by lazy.nvim |
| `tmux/` | tmux options and plugins managed by tpack |
| `zsh/` | Shell environment, aliases, completion, prompt, and plugins |

## Installation

Clone the repository somewhere outside `~/.config`, then symlink each managed
directory into place. Replace `<repository-url>` with this repository's URL.

```sh
git clone <repository-url> "$HOME/.dotfiles"
mkdir -p "$HOME/.config"

for config in kitty neofetch nvim tmux zsh; do
    target="$HOME/.config/$config"
    if [ -e "$target" ] || [ -L "$target" ]; then
        mv "$target" "$target.backup"
    fi
    ln -s "$HOME/.dotfiles/$config" "$target"
done

if [ -e "$HOME/.zshenv" ] || [ -L "$HOME/.zshenv" ]; then
    mv "$HOME/.zshenv" "$HOME/.zshenv.backup"
fi
ln -s "$HOME/.config/zsh/.zshenv" "$HOME/.zshenv"
exec zsh -l
```

Review existing backups before removing them. Applications following the XDG
configuration convention will discover the symlinked directories automatically.
The `.zshenv` link sets `ZDOTDIR` so Zsh can find the rest of its files.

## Requirements

The configuration targets Apple Silicon macOS with Homebrew under
`/opt/homebrew`; Intel Homebrew under `/usr/local` is also detected. Install only
the tools needed for the configurations you use.

- Kitty with MonoLisa and Symbols Nerd Font
- Neovim 0.12 or newer, Git, ripgrep, tree-sitter-cli, Node.js, and Python
- tmux with `tpack` available on `PATH`
- Zsh, eza, lazygit, yt-dlp, GnuPG, and pnpm
- Optional TeX tooling: latexmk, latexindent, and Skim

Neovim installs lazy.nvim and its declared plugins on first launch. The first
interactive Zsh session shallow-clones missing plugins. Update them later with:

```sh
zsh-update-plugins
```

The Neovim lockfile records tested plugin revisions. Use `:Lazy restore` to
restore them, `:Lazy update` to update them, and `:Mason` to manage configured
language servers and formatters.

## Useful checks

Validate the Zsh files without starting an interactive shell:

```sh
for file in zsh/.zshenv zsh/.zprofile zsh/.zshrc zsh/.zsh/*.zsh; do
    zsh -n "$file" || exit
done
```

Run the Neovim integration smoke test after its plugins are installed:

```sh
nvim --headless '+lua dofile("nvim/tests/smoke.lua")'
```

For Neovim troubleshooting, use `:checkhealth`, `:checkhealth vim.lsp`, and
`:ConformInfo`. For tmux, plugin declarations are in `tmux/tmux.conf`; downloaded
plugin directories are intentionally not versioned.
