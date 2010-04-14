# use bash in emacs
if [[ "$EMACS" == "t" ]]
then
  exec bash --login
fi


fpath+="$HOME/.zsh.d/completion"
for conf_file ($HOME/.zsh.d/S[0-9][0-9]*) source $conf_file
unset conf_file
