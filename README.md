# dotfiles

Personal configuration for bash, Fastfetch, Kitty, Neovim, tmux, and Zsh. Primarily
macOS, with the shell and Neovim also working on Ubuntu, Arch, and Raspberry Pi
OS. Caches, shell history, downloaded plugins, plugin lockfiles, and macOS
metadata are not versioned.

## Included configuration

| Directory | Purpose |
| --- | --- |
| `bash/` | Lighter bash setup: zsh-style prompt, history, fzf, readline tweaks |
| `fastfetch/` | System-information modules, including local and public IP |
| `kitty/` | Terminal font, window, symbol, bell, and color settings |
| `nvim/` | Neovim setup using the built-in `vim.pack` plugin manager |
| `nvim-lazy/` | Previous lazy.nvim-based Neovim setup, kept for reference |
| `shell/` | Environment, aliases, and functions shared by zsh and bash |
| `tmux/` | tmux options and plugins managed by tpack |
| `zsh/` | Shell environment, aliases, completion, prompt, fzf, and plugins |

## Installation

Clone the repository to `~/dotfiles`, then symlink each managed directory into
`~/.config`. Existing configurations are moved aside as `*.backup`.

```sh
git clone https://github.com/tibi1220/dotfiles.git "$HOME/dotfiles"
mkdir -p "$HOME/.config"

for config in bash fastfetch kitty nvim shell tmux zsh; do
    target="$HOME/.config/$config"
    if [ -e "$target" ] || [ -L "$target" ]; then
        mv "$target" "$target.backup"
    fi
    ln -s "$HOME/dotfiles/$config" "$target"
done

if [ -e "$HOME/.zshenv" ] || [ -L "$HOME/.zshenv" ]; then
    mv "$HOME/.zshenv" "$HOME/.zshenv.backup"
fi
ln -s "$HOME/.config/zsh/.zshenv" "$HOME/.zshenv"

for file in .bashrc .bash_profile; do
    if [ -e "$HOME/$file" ] || [ -L "$HOME/$file" ]; then
        mv "$HOME/$file" "$HOME/$file.backup"
    fi
    ln -s "$HOME/.config/bash/$file" "$HOME/$file"
done
exec zsh -l
```

Review the backups before removing them. The `.zshenv` link sets `ZDOTDIR` so
Zsh can find the rest of its files; bash reads `~/.bashrc` and `~/.bash_profile`
directly.

To try the previous Neovim setup alongside the current one:

```sh
ln -s "$HOME/dotfiles/nvim-lazy" "$HOME/.config/nvim-lazy"
NVIM_APPNAME=nvim-lazy nvim
```

## Platforms

- **macOS** (Apple Silicon; Intel Homebrew under `/usr/local` is also detected).
  Homebrew setup and the `bup`/`bs*` brew aliases are macOS only.
- **Linux** (Ubuntu, Arch, Raspberry Pi OS). The `linux` Zsh plugin provides
  equivalents of the macOS helpers (`ofd`, `tab`/`split_tab` via tmux,
  `music` via playerctl, …). Clipboard helpers (`copydir`, `copyfile`, Ctrl-O)
  use `wl-clipboard`, `xclip`/`xsel`, tmux, or OSC 52 over SSH.

### Neovim profiles

`zsh/.zsh/env.zsh` exports `NVIM_PROFILE`: `essential` on a Raspberry Pi,
`full` everywhere else. The essential profile skips Tree-sitter, LSP
(including completion and formatting), and the LaTeX and Markdown modules.
Override it per launch, e.g. `NVIM_PROFILE=full nvim`.

## Requirements

Install only the tools needed for the configurations you use.

- **Kitty** with MonoLisa and Symbols Nerd Font
- **Neovim** 0.12 or newer, Git, make, curl, ripgrep, fd, and lazygit
- **Neovim, full profile:** tree-sitter-cli and a C compiler; language servers
  `lua-language-server`, `pyright`, `clangd`, `emmet-ls`, `texlab`; formatters
  `stylua`, `ruff`, `prettier`, `latexindent`
- **LaTeX:** latexmk and Skim (macOS)
- **tmux** with `tpack` available on `PATH`
- **Zsh** with eza, fzf, fd, bat, GnuPG, and pnpm
- **bash** 4 or newer (macOS: `brew install bash`; `/bin/bash` 3.2 is too old),
  optionally `bash-completion` for git/ssh/package completions
- **Fastfetch**
- **Linux extras:** `wl-clipboard` or `xclip`, `xdg-utils`, and optionally `playerctl`

Language servers and formatters are not installed automatically; put them on
`PATH`.

## Plugins

Neovim installs its plugins with `vim.pack` on first launch and builds
telescope-fzf-native and the Markdown Preview server automatically. If a
build fails (e.g. offline), Neovim warns and keeps starting. Update plugins
with:

```vim
:lua vim.pack.update()
```

The first interactive Zsh session shallow-clones missing plugins. Update them
later with:

```sh
zsh-update-plugins
```

tmux plugins are declared in `tmux/tmux.conf` and installed by tpack.

## Useful checks

Validate the Zsh files without starting an interactive shell:

```sh
for file in zsh/.zshenv zsh/.zprofile zsh/.zshrc zsh/.zsh/*.zsh zsh/.zsh/functions/*.zsh; do
    zsh -n "$file" || exit
done
```

For Neovim troubleshooting, use `:checkhealth`, `:checkhealth vim.lsp`, and
`:ConformInfo`.

The previous setup has a smoke test (requires the `nvim-lazy` link above):

```sh
cd nvim-lazy && NVIM_APPNAME=nvim-lazy nvim --headless '+lua dofile("tests/smoke.lua")'
```
