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

function _set_helper() {
    local cmd_name="$1"
    test -z "$cmd_name" && cmd_name="$2"
    shift
    shift

    alias "$cmd_name"="$*"
}
