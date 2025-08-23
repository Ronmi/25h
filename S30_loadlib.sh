#!/usr/bin/zsh -f

_rmi_loaded_lib=()

function loadlib {
    f="${HOME}/.zsh.d/lib/${1}.sh"
    if [[ -f "$f" ]]
    then
        if [[ "${_rmi_loaded_lib[(r)$1]}" != "" ]]
        then
            return 0
        fi
        _rmi_loaded_lib+=("$1")
        source "$f"
    fi
}

function loadlib_again {
    if [[ "${_rmi_loaded_lib[(r)$1]}" != "" ]]
    then
        loadlib "$1"
        return $?
    fi

    f="${HOME}/.zsh.d/lib/${1}.sh"
    if [[ -f "$f" ]]
    then
        source "$f"
    fi
}
