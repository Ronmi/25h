#!/usr/bin/zsh -f
# python helpers

# disable venv prompt by default
export VIRTUAL_ENV_DISABLE_PROMPT=1

function use_venv {
    ve="${_RMI_WORK_DIR}/venv"
    if [[ ! -f "${ve}/bin/activate" ]]
    then
        echo "Creating virtualenv in .rmi-work/venv..."
        python -m venv "${ve}" "$@"
    fi
    source "${ve}/bin/activate"
    unset ve
}

function use_conda {
    ve="${_RMI_WORK_DIR}/conda_env"
    name="$(basename "$_RMI_WORK_HERE")"
    if [[ ! -d "${ve}" ]]
    then
        conda create -y --prefix "${ve}" "$@"
    fi
    conda activate "${ve}"
    unset ve
}
