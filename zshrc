#!/usr/bin/zsh -f

fpath+="$HOME/.zsh.d/completion"
fpath+="$HOME/.zfunc"
for conf_file ($HOME/.zsh.d/S[0-9][0-9]*) source $conf_file
unset conf_file
