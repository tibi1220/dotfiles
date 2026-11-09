# Classic Debian/Ubuntu-style prompt:  user@host:~/full/path$
# Bold green user@host, bold blue path. Python venvs add their own "(venv) ".
PS1='\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '

# Share history between open shells
PROMPT_COMMAND="history -a; history -n${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
