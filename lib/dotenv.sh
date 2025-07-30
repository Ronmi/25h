#!/usr/bin/zsh -f
# source .env automatically or on-demand

# This special envvar is used to enable autoloading
if [[ "$_RMI_DOTENV_AUTOLOAD" == "1" && -f "${_RMI_WORK_HERE}/.env" ]]
then
    source "${_RMI_WORK_HERE}/.env"
fi
if [[ "$_RMI_DOTENV_AUTOLOAD" != "" && -f "$_RMI_DOTENV_AUTOLOAD" ]]
then
    source "$_RMI_DOTENV_AUTOLOAD"
fi

# create a subshell and load .env.
function useenv() {
    local f="${1:-${_RMI_WORK_HERE}/.env}"
    if [[ ! -f "$f" ]]
    then
        echo "no env file found in ${f}"
        echo
        echo "Usage: useenv [env_file]"
        echo
        echo "It will use ${_RMI_WORK_HERE}/.env if no env_file specified"
        return 1
    fi
    (
        source "$f"
        "$SHELL"
    )
}
