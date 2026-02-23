PATH="${HOME}/bin/composer:${HOME}/bin/cargo:${HOME}/bin/node:${HOME}/bin/yarn:${HOME}/bin/pnpm:${HOME}/bin/golang:${HOME}/bin:${HOME}/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

export PATH

if [[ "$TERM" != "dumb" ]]
then
    export GPG_TTY="$(tty)"
fi
