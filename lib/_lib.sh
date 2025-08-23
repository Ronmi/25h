#!/usr/bin/zsh -f

function _has_prog() {
    whence -p "$1" > /dev/null 2>&1
}

function _has_func() {
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

function _args_to_json() {
  printf '%s\n' "$@" | jq -R . | jq -scM .
}

function _set_helper() {
    local cmd_name="$1"
    test -z "$cmd_name" && {
        echo "Usage: _set_helper <alias_name> <helper_name> <command...>"
        return 1
    }
    shift
    local name="$1"
    shift
    if [[ $# -eq 0 ]]
    then
        echo "Usage: _set_helper <alias_name> <helper_name> <command...>"
        return 1
    fi

    alias "$cmd_name"="$*"

    echo "${name} helper has been installed, run '${cmd_name}' to use it."
}

function _confirm_shell() {
    echo -n "$1 [y/N]" 1>&2
    read -q ans || {
        local err=$?
        echo 1>&2
        return $err
    }
}

function _confirm_gum() {
    gum confirm "$1" || return $?
}

function _confirm() {
    which gum > /dev/null 2>&1 && {
        _confirm_gum "$1"
        return $?
    } || {
        _confirm_shell "$1"
        return $?
    }
}

##################### color functions

# $1 is a number of color (0-15)
function _set_fgc() {
    local base=$1
    _has_prog tput
    if [[ $? -eq 0 ]]
    then
        tput setaf $base
    else
        base=$((base + 30))
        echo -n "\033[${base}m"
    fi
}

# $1 is a number of color (0-15)
function _set_bgc() {
    local base=$1
    _has_prog tput
    if [[ $? -eq 0 ]]
    then
        tput setab $base
    else
        base=$((base + 40))
        echo -n "\033[${base}m"
    fi
}

function _font_reset() {
    _has_prog tput
    if [[ $? -eq 0 ]]
    then
        tput sgr0
    else
        echo -n "\033[0m"
    fi
}

function _font_bold() {
    _has_prog tput
    if [[ $? -eq 0 ]]
    then
        tput bold
    else
        echo -n "\033[1m"
    fi
}

###### misc

function _download_latest_release_from_github() {
    if [[ $# -lt 3 ]]
    then
        echo "Usage: _download_latest_from_github <owner> <repo> <file> [options for wget ...]"
        return 1
    fi

    local fn="$3"
    local uri="$(wget -qO - "https://api.github.com/repos/${1}/${2}/releases/latest" | grep browser_download_url | grep -F "$fn" | cut -d : -f 2- | jq . -r)"
    shift;shift;shift
    _has_arg -O "$@" && {
        wget "$uri" "$@"
        return $?
    }
    wget -O "$fn" "$uri" "$@"
}
