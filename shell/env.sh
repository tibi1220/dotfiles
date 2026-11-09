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
