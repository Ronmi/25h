#!/usr/bin/zsh -f

# disable venv prompt by default
export VIRTUAL_ENV_DISABLE_PROMPT=1

# activate (and setup if needed) virtualenv in "${_RMI_WORK_HERE}/.rmi-work/pyvenv"
# all arguments are passed to virtualenv
function pyve {
    ve="${_RMI_WORK_HERE}/.rmi-work/pyvenv"
    if [[ ! -f "${ve}/bin/activate" ]]
    then
        virtualenv "$@" "$ve"
    fi
    source "${ve}/bin/activate"
}
