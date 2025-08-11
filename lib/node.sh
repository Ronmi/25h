#!/usr/bin/zsh -f
# *will be* javescript/typescript helpers

node -v > /dev/null 2>&1 || {
    echo "Node.js is not installed. Please install Node.js to use this script."
}

function _use_yarn() {
    command -v yarn >/dev/null 2>&1 || return 1
    find . -name 'yarn.lock' -print -quit | grep -q . || return 1
}

function _use_pnpm() {
    command -v pnpm >/dev/null 2>&1 || return 1
    find . -name 'pnpm-lock.yaml' -print -quit | grep -q . || return 1
}

function NODE_PM() {
    if [[ _use_pnpm ]]; then
        pnpm "$@"
    elif [[ _use_yarn ]]; then
        yarn "$@"
    else
        npm "$@"
    fi
}

function NODE_PX() {
    if [[ _use_pnpm ]]; then
        pnpx "$@"
    else
        npx "$@"
    fi
}

