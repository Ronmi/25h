#!/usr/bin/zsh -f

# defaut path
PATH="${HOME}/bin/composer:${HOME}/bin/cargo:${HOME}/bin/node:${HOME}/bin/yarn:${HOME}/bin/pnpm:${HOME}/bin/golang:${HOME}/bin:${HOME}/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

fpath+="$HOME/.zsh.d/completion"
fpath+="$HOME/.zfunc"
for conf_file ($HOME/.zsh.d/S[0-9][0-9]*) source $conf_file
unset conf_file
