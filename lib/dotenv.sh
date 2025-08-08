#!/usr/bin/zsh -f
# source .env automatically or on-demand, set _RMI_DOTENV_AUTOLOAD to 1 (or a file) to enable autoloading, or run `useenv` to load a specific .env file in a subshell

_env_file="${_RMI_WORK_HERE}/.env"
local _do=0

# This special envvar is used to enable autoloading
if [[ "$_RMI_DOTENV_AUTOLOAD" == "1" ]]
then
    _env_file="${_RMI_WORK_HERE}/.env"
    _do=1
elif [[ "$_RMI_DOTENV_AUTOLOAD" != "" ]]
then
    _env_file="${_RMI_DOTENV_AUTOLOAD}"
    if [[ "$_env_file" != /* ]]
    then
        _env_file="${_RMI_WORK_HERE}/${_env_file}"
    fi
    _do=1
fi

if [[ _do -eq 1 && -f "$_env_file" ]]
then
    source "$_env_file"
fi
unset _do

# create a subshell and load .env.
function useenv() {
    local f="${1:-${_env_file}}"
    if [[ ! -f "$f" ]]
    then
        echo "no env file found in ${f}"
        echo
        echo "Usage: useenv [env_file]"
        echo
        echo "It will use ${_env_file} if no env_file specified"
        return 1
    fi
    (
        source "$f"
        "$SHELL"
    )
}
