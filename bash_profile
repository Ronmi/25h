# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# this line is only for emacs tramp
PATH="${HOME}/bin/composer:${HOME}/bin/cargo:${HOME}/bin/node:${HOME}/bin/yarn:${HOME}/bin/pnpm:${HOME}/bin/golang:${HOME}/bin:${HOME}/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

PATH="$(zsh -l -c 'echo $PATH')"

export PATH
