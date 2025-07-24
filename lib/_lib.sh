#!/bin/zsh -f

function test_func {
    whence -w "$1" | cut -d : -f 2 | grep function > /dev/null 2>&1
}

function _log_action {
    echo -n "${1}... "
}

function _log_result {
    if [[ $1 == 0 ]]
    then
        echo done.
    else
        echo failed.
    fi
}

function _prepare_file {
    touch "$1"
}

function _append_if_non_exist {
    _prepare_file "$1"
    grep -F "$2" "$1" >/dev/null 2>&1
    if [[ $? == 0 ]]
    then
        return
    fi

    data="$3"
    if [[ $data == "" ]]
    then
        data="$2"
    fi
    echo "$3" >> "$1"
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
