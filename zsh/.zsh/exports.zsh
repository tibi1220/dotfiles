# Git verify commits
[[ -n $TTY ]] && export GPG_TTY=$TTY

# Java
if [[ -n $HOMEBREW_PREFIX && -d $HOMEBREW_PREFIX/opt/openjdk/include ]]; then
  export CPPFLAGS="-I$HOMEBREW_PREFIX/opt/openjdk/include${CPPFLAGS:+ $CPPFLAGS}"
fi
# export MATLAB_JAVA="/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home"
