# dotfiles

Personal configuration for bash, bat, btop, Fastfetch, Kitty, lazygit, Neovim,
tmux, and Zsh, all in the Nightfox color scheme. Primarily macOS, with the
shell and Neovim also working on Ubuntu, Arch, and Raspberry Pi OS. Caches,
shell history, downloaded plugins, plugin lockfiles, and macOS metadata are
not versioned.

## Included configuration

| Directory | Purpose |
| --- | --- |
| `bash/` | Lighter bash setup: simple `user@host:path$` prompt, history, fzf, readline tweaks |
| `bat/` | bat settings and the Nightfox theme (also used by fzf's file previews) |
| `btop/` | btop settings and a Nightfox theme (`themes/nightfox.theme`) |
| `fastfetch/` | System-information modules, including local and public IP |
| `kitty/` | Terminal font, window, symbol, bell, and color settings |
| `lazygit/` | lazygit settings and Nightfox colors; returns straight to lazygit after the editor exits |
| `nvim/` | Neovim setup using the built-in `vim.pack` plugin manager |
| `shell/` | Environment, aliases, functions, and fzf settings (with Nightfox colors) shared by zsh and bash; found via the repo path, no link needed |
| `tmux/` | tmux options and plugins managed by tpack |
| `zsh/` | Shell environment, options, completion, prompt, fzf, and plugins |

## Installation

Clone the repository, then run the setup script:

```sh
git clone https://github.com/tibi1220/dotfiles.git "$HOME/dotfiles"
"$HOME/dotfiles/install.sh"
exec zsh -l
```

`install.sh` links each config folder into `~/.config`, plus the files that
programs look for elsewhere:

- `~/.zshenv`, which sets `ZDOTDIR` so Zsh finds the rest of its files
- `~/.bashrc` and `~/.bash_profile`, which bash reads directly
- on macOS, lazygit's `config.yml` in `~/Library/Application Support/lazygit`
  (lazygit reads its config from there instead of `~/.config`; its own
  state files stay in that folder)

It also rebuilds bat's theme cache so the Nightfox theme is found.

Links that are already correct are left alone, so the script can be run again
at any time, e.g. after adding a folder. Anything else already in the way is
skipped and reported. Options:

| Option | Effect |
| --- | --- |
| `--force` | Also replace what's in the way. It is moved aside as `<name>.backup` (or `<name>.backup.<date-time>`), not deleted. |
| `--dry-run` | Only show what would be done. |
| `--help` | Show the usage. |

Review backups before removing them.

## Platforms

- **macOS** (Apple Silicon; Intel Homebrew under `/usr/local` is also detected).
  Homebrew setup and the `bup`/`bs*` brew aliases are macOS only. The `macos`
  Zsh plugin adds `cdf` (cd to the front Finder window) and `man-preview`.
- **Linux** (Ubuntu, Arch, Raspberry Pi OS). The `linux` Zsh plugin adds
  desktop helpers (`ofd`, `tab`/`split_tab` via tmux, `quick-look`,
  `man-preview`, …). Clipboard helpers (`copydir`, `copyfile`, Ctrl-O)
  use `wl-clipboard`, `xclip`/`xsel`, tmux, or OSC 52 over SSH.

### Neovim profiles

`shell/env.sh` exports `NVIM_PROFILE`: `essential` on a Raspberry Pi, `full`
everywhere else. The essential profile skips Tree-sitter, LSP (including
completion and formatting), and the LaTeX and Markdown modules. Override it
per launch, e.g. `NVIM_PROFILE=full nvim`.

## Colors

Everything uses Nightfox, from
[nightfox.nvim](https://github.com/EdenEast/nightfox.nvim): Kitty, tmux,
Neovim, the zsh prompt, `LS_COLORS` (eza-style), fzf, bat, btop, and lazygit.
bat's theme (`bat/themes/nightfox.tmTheme`) is nightfox.nvim's own; after
changing anything in `bat/themes/`, run `bat cache --build`.

### Welcome screen trains

The welcome screen's **Trains** entry (`t`) shows or hides the trains, a
night scene from an iPhone lock-screen tweak behind the menu: a town with a
tram stop, trams arriving, opening their doors and leaving, and the moon in
today's phase. They're off when Neovim starts, and stop as soon as a file is
opened. The code is in `nvim/lua/locktrains/`, drawn one of two ways:

- **In kitty** (`kitty.lua`), as real images at the screen's resolution,
  filling the whole welcome screen: the starry sky behind the menu, which is
  centered between the top of the screen and the overhead wires, and the
  town along the bottom. The trams' cars are about 4 rows tall whatever the
  font size, with their headlights' beam and tail lights shimmering, and the
  stars twinkle (each a tiny animation kitty plays by itself); each art pixel
  is shown as an exact block of screen pixels, so it stays sharp. Works
  inside tmux too (needs `allow-passthrough on` and `focus-events on`; there,
  the commands are sent in batches, as tmux drops some of a big burst). The
  pictures go to kitty through temporary files, and only the train's
  position is sent each frame; while Neovim waits for the rest of a
  mapping (after `<leader>`), the train is moved by writing those few
  commands straight to the terminal. It keeps running while kitty isn't focused
  and next to splits like the file tree; it only pauses while another tmux
  window is shown, and hides behind floating windows (the file picker). The
  text cursor is hidden while the welcome screen has the focus.
- **Anywhere else** (`text.lua`, e.g. over SSH), under the menu, with `▀`
  cells in true color, two art pixels a cell.

`:Trains` keeps them running while editing (kitty only, `strip.lua`): a
strip across the screen's first rows, above everything else, with just the
town, the overhead wires, the platform, and the trams; no sky. It's a
split, so it takes its rows from the windows below instead of covering
text. The bufferline tab bar moves under it (drawn there in a floating
window; clicking its tabs doesn't work then), and the minimap and file
tree (Neo-tree) start below it too. `:Trains` shows or hides it, `:Trains 8` sets its height (7 rows by
default), and `q` in it hides it. It hides behind floating windows (the
picker, completion, hover docs).

The art is homepi-admin's own pixel art, rendered and converted into Lua. The
images use big scenes drawn with `--scale`, so the trains keep their size and
the town widens around them; the window shows the part that fits, and the
trams come in from just outside it. The welcome screen's (`art/wide.lua`,
1800×860) fills terminals up to about 460 columns at any font size. The
strip's (`art/strip.lua`, 6000 wide, without the sky) is wider, as it's
scaled up less. To regenerate them:

```sh
cd ~/Documents/Home/homepi-admin
pnpm lock-trains /tmp/trains-wide --width 1800 --height 860 --scale 0.4792
pnpm lock-trains /tmp/trains-strip --width 6000 --height 860 --scale 0.4792
python3 ~/dotfiles/nvim/scripts/locktrains-art.py /tmp/trains-wide \
    ~/dotfiles/nvim/lua/locktrains/art/wide.lua
python3 ~/dotfiles/nvim/scripts/locktrains-art.py --no-sky /tmp/trains-strip \
    ~/dotfiles/nvim/lua/locktrains/art/strip.lua
```

The text version uses sets as wide as the terminal (120, 160, 200 columns):
`--width <columns> --height <2 × rows>` (e.g. `--width 160 --height 72`) and
`art/w<columns>.lua`.

## Requirements

Install only the tools needed for the configurations you use.

- **Kitty** with MonoLisa and Symbols Nerd Font
- **Neovim** 0.12 or newer, Git, curl, ripgrep, fd, and lazygit
- **Neovim, full profile:** tree-sitter-cli and a C compiler; language servers
  `lua-language-server`, `pyright`, `clangd`, `emmet-ls`, `texlab`; formatters
  `stylua`, `ruff`, `prettier`, `latexindent`
- **LaTeX:** latexmk and Skim (macOS)
- **tmux** with `tpack` available on `PATH`
- **Zsh** with eza, fzf, fd, bat, GnuPG, and pnpm
- **bash** 4 or newer (macOS: `brew install bash`; `/bin/bash` 3.2 is too old),
  optionally `bash-completion` for git/ssh/package completions
- **btop**, **lazygit**, **Fastfetch**
- **Linux extras:** `wl-clipboard` or `xclip`, `xdg-utils`, and optionally `playerctl`

Language servers and formatters are not installed automatically; put them on
`PATH`.

## Plugins

Neovim installs its plugins with `vim.pack` on first launch; nothing needs
to be built. snacks.nvim provides the picker (`<C-p>`, `<leader>f…`), the
F12 terminal, lazygit (`<leader>gg`), and the welcome screen. Markdown is
previewed in the browser with `:LivePreview start` (or `:MarkdownPreview`).

To show the first screen sooner, git signs, color previews, Tree-sitter,
LSP and completion, and the LaTeX and Markdown plugins are loaded right
after it is drawn (`nvim/lua/config/deferred.lua`); files opened from the
command line are then set up for them too. The welcome screen's time is
until that first screen.

Update plugins with:

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

Validate the shell files without starting an interactive shell:

```sh
for file in zsh/.zshenv zsh/.zprofile zsh/.zshrc zsh/lib/*.zsh zsh/lib/functions/*.zsh; do
    zsh -n "$file" || exit
done
for file in bash/.bashrc bash/.bash_profile bash/*.bash shell/*.sh shell/functions/*.sh; do
    bash -n "$file" || exit
done
sh -n install.sh
```

For Neovim troubleshooting, use `:checkhealth`, `:checkhealth vim.lsp`, and
`:ConformInfo`.
