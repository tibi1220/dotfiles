# Login/interactive environment shared by zsh and bash: PATH, tools, editor.
# Safe to source more than once; PATH entries are moved to the front rather
# than duplicated.

# Move (or add) a directory to the front of PATH.
_dotfiles_path_prepend() {
  local p=":$PATH:"
  p=${p//:$1:/:}
  p=${p#:}
  p=${p%:}
  PATH="$1${p:+:$p}"
}

if [[ $OSTYPE == darwin* ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm"
fi

# Homebrew (macOS only)
if [[ $OSTYPE == darwin* && -d /opt/homebrew ]]; then
  export HOMEBREW_PREFIX=/opt/homebrew
elif [[ $OSTYPE == darwin* && -d /usr/local/Homebrew ]]; then
  export HOMEBREW_PREFIX=/usr/local
fi

if [[ -n $HOMEBREW_PREFIX ]]; then
  export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
  export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX"
  case ":$MANPATH:" in
    *":$HOMEBREW_PREFIX/share/man:"*) ;;
    *) export MANPATH="$HOMEBREW_PREFIX/share/man${MANPATH+:$MANPATH}:" ;;
  esac
  case ":$INFOPATH:" in
    *":$HOMEBREW_PREFIX/share/info:"*) ;;
    *) export INFOPATH="$HOMEBREW_PREFIX/share/info${INFOPATH:+:$INFOPATH}" ;;
  esac
  _dotfiles_path_prepend "$HOMEBREW_PREFIX/sbin"
  _dotfiles_path_prepend "$HOMEBREW_PREFIX/bin"
fi

# pnpm: newer versions put binaries in $PNPM_HOME/bin, older ones in $PNPM_HOME.
_dotfiles_path_prepend "$PNPM_HOME"
_dotfiles_path_prepend "$PNPM_HOME/bin"
_dotfiles_path_prepend "$HOME/.cargo/bin"
_dotfiles_path_prepend "$HOME/.local/bin"
export PATH
unset -f _dotfiles_path_prepend

# Code editors
export EDITOR=nvim
export VISUAL=nvim

# File colors, copied from eza's defaults so that eza, zsh completion menus
# and GNU tools (ls, tree, fd) all color files the same way. Codes: 1 bold,
# 2 dim, 4 underline; 31 red, 32 green, 33 yellow, 34 blue, 35 magenta,
# 36 cyan. eza reads this too, so changing a color here changes it there.
_ls_colors=(
  # File types
  'di=1;34' # directory
  'ex=1;32' # executable
  'ln=36'   # symlink
  'pi=33'   # named pipe
  'so=1;31' # socket
  'bd=1;33' # block device
  'cd=1;33' # character device

  # Build files (bold underlined yellow)
  '*Makefile=1;4;33' '*Dockerfile=1;4;33' '*CMakeLists.txt=1;4;33'
  '*package.json=1;4;33' '*Cargo.toml=1;4;33' '*build.gradle=1;4;33'

  # Source code (bold yellow)
  '*.c=1;33' '*.h=1;33' '*.cpp=1;33' '*.hpp=1;33' '*.py=1;33' '*.lua=1;33'
  '*.js=1;33' '*.ts=1;33' '*.rs=1;33' '*.go=1;33' '*.java=1;33'
  '*.css=1;33' '*.tex=1;33'

  # Compiled (yellow)
  '*.o=33' '*.a=33' '*.so=33' '*.dylib=33' '*.pyc=33' '*.class=33'

  # Images (magenta), video (bold magenta)
  '*.png=35' '*.jpg=35' '*.jpeg=35' '*.gif=35' '*.webp=35' '*.svg=35'
  '*.bmp=35' '*.tiff=35' '*.ico=35' '*.heic=35' '*.raw=35'
  '*.mp4=1;35' '*.mkv=1;35' '*.mov=1;35' '*.webm=1;35' '*.avi=1;35'
  '*.m4v=1;35'

  # Audio (cyan), lossless audio (bold cyan)
  '*.mp3=36' '*.ogg=36' '*.m4a=36' '*.aac=36' '*.opus=36'
  '*.flac=1;36' '*.wav=1;36' '*.aiff=1;36' '*.alac=1;36'

  # Documents (green), keys and signatures (bold green)
  '*.pdf=32' '*.doc=32' '*.docx=32' '*.odt=32' '*.rtf=32' '*.xls=32'
  '*.xlsx=32' '*.ppt=32' '*.pptx=32' '*.key=32'
  '*.gpg=1;32' '*.asc=1;32' '*.sig=1;32' '*.pem=1;32' '*.crt=1;32'

  # Archives and disk images (red)
  '*.zip=31' '*.tar=31' '*.gz=31' '*.tgz=31' '*.xz=31' '*.bz2=31'
  '*.zst=31' '*.7z=31' '*.rar=31' '*.dmg=31' '*.iso=31' '*.deb=31'

  # Temporary and backup files (dim)
  '*~=2' '*.tmp=2' '*.bak=2' '*.swp=2'
)
LS_COLORS=$(IFS=:; printf '%s' "${_ls_colors[*]}")
export LS_COLORS
unset _ls_colors

# Neovim profile: lightweight setup on a Raspberry Pi, everything elsewhere.
if grep -qa "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
  export NVIM_PROFILE=essential
else
  export NVIM_PROFILE=full
fi

# Git commit signing needs to know the terminal
if [[ -n $TTY ]]; then
  export GPG_TTY=$TTY # zsh
elif [[ -t 0 ]]; then
  export GPG_TTY=$(tty)
fi

# Java headers from Homebrew's openjdk
if [[ -n $HOMEBREW_PREFIX && -d $HOMEBREW_PREFIX/opt/openjdk/include ]]; then
  case " $CPPFLAGS " in
    *" -I$HOMEBREW_PREFIX/opt/openjdk/include "*) ;;
    *) export CPPFLAGS="-I$HOMEBREW_PREFIX/opt/openjdk/include${CPPFLAGS:+ $CPPFLAGS}" ;;
  esac
fi
# export MATLAB_JAVA="/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home"
