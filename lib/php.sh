#!/bin/zsh -f

function phpdoc {
    docker run -it --rm -v "${_RMI_WORK_HERE}:/data" phpdoc/phpdoc:3 "$@"
    docker run -it --rm -v "${PWD}:/data" --entrypoint /bin/chown phpdoc/phpdoc:3 -R "$(id -u):$(id -g)" /data/build
}
