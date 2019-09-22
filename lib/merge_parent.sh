#!/usr/bin/zsh -f

if [[ $__tmp_wh == "" ]]
then
    __tmp_wh="$_RMI_WORK_HERE"
fi
__tmp_parent="$(dirname "$_RMI_WORK_HERE")"

if [[ -f "${__tmp_parent}/.rmi-work/conf.zsh" ]]
then
    # as if we're work there
    _RMI_WORK_HERE="$__tmp_parent"
    _RMI_WORK_DIR="$__tmp_parent/.rmi-work"
    source "${__tmp_parent}/.rmi-work/conf.zsh"
fi

unset __tmp_parent
_RMI_WORK_HERE="$__tmp_wh"
_RMI_WORK_DIR="$__tmp_wh/.rmi-work"
