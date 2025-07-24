#!/bin/zsh -f

function _has_func {
    whence -w "$1" | cut -d : -f 2 | grep function > /dev/null 2>&1
}

function _has_arg() {
    local arg="$1"
    shift

    for i in "$@"
    do
        if [[ "$i" == "$arg" ]]
        then
            return 0
        fi
    done
    return 1
}
