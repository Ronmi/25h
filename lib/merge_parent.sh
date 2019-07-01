#!/usr/bin/zsh -f

__tmp_parent="$(dirname "$_RMI_WORK_HERE")"

if [[ -f "${__tmp_parent}/.rmi-work/conf.zsh" ]]
then
    source "${__tmp_parent}/.rmi-work/conf.zsh"
fi

unset __tmp_parent
