#!/usr/bin/zsh -f
# helper script, should not be loaded directly

function _func_definer {
    x="$(whence -v "$1"|grep -F 'shell function'|grep -oE 'from .*')"
    if [[ $? != 0 ]]
    then
        return 1
    fi
    echo "$x"|cut -d ' ' -f 2-
}
