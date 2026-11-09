# Programmable completion (git branches, ssh hosts, brew/apt packages, ...)
# from the bash-completion package, if installed:
#   macOS: brew install bash-completion@2   Debian/Ubuntu/Pi OS: apt install bash-completion
#   Arch:  pacman -S bash-completion
for __bc in \
  "${HOMEBREW_PREFIX:-/nonexistent}/etc/profile.d/bash_completion.sh" \
  /usr/share/bash-completion/bash_completion \
  /etc/bash_completion; do
  if [[ -r $__bc ]]; then
    source "$__bc"
    break
  fi
done
unset __bc
