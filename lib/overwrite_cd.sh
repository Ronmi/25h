#!/usr/bin/zsh -f
# overwrite cd, identical to "backroot" if call without arg

function cd {
    if [[ $# -eq 0 ]]
    then
        builtin cd "$_RMI_WORK_HERE"
    else
        builtin cd "$@"
    fi
}
