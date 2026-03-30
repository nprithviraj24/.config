# Fancy way to show 
PS1='\[\033[1;34m\]\W →  \[\033[m\]'

# This one for tmux
[[ $TERM != "screen-256color" ]] && exec tmux -u
