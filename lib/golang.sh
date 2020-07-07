#!/usr/bin/zsh -f

loadlib _lib
__my_gobase="${_RMI_WORK_DIR}/golang"

function dc_go_init {
    cat <<EOF > ./docker-compose.yml
version: "3"

services:
EOF
    dc_go_append
}

function dc_go_append {
    if [[ ! -f ./docker-compose.yml ]]
    then
        dc_go_init
        return
    fi
    cat <<EOF >> ./docker-compose.yml
  srv:
    image: golang
    volumes:
      - ".:/src"
    user: "\$UID:\$GID"
    command: bash -c 'go mod download && go build -o /tmp/myprog && exec /tmp/myprog'
EOF
}

# download/update useful tools for developing software with go
function dl_go_tools {
    go get -u github.com/stamblerre/gocode
    go get -u golang.org/x/tools/cmd/...
}

function _dl_go_build_tools {
    tgz="https://golang.org/dl/go${1}.linux-amd64.tar.gz"
    _log_action "Getting latest golang build tools"
    wget -q -O - "$tgz" | tar zxf - -C "$__my_gobase" >/dev/null 2>&1
    _log_result $?
}

function _dl_go_latest {
    _log_action "Detecting latest golang version"
    tgz="$(wget -q -O - https://golang.org/dl/ | grep -oE 'go[0-9]\.[0-9]+\.[0-9]+\.linux-amd64\.tar\.gz' | head -n 1)"
    ver="$(echo "$tgz"|grep -oE '[0-9]\.[0-9]+\.[0-9]+')"
    if [[ $ver == "" ]]
    then
        echo failed.
        return
    fi
    echo "$ver"

    _dl_go_build_tools "$ver"
}

function dl_goruntime {
    if [[ -d "${__my_gobase}/go" ]]
    then
        return
    fi

    if [[ $1 == "" ]]
    then
        _dl_go_latest
        return
    fi

    _dl_go_build_tools "$1"
}

function _prepare_goenv {
    export GOENV="${__my_gobase}/envfile"
    mkdir -p "$(dirname "$GOENV")"
    _prepare_file "$GOENV"
}

function set_goenv {
    _prepare_goenv
    _append_if_non_exist "$GOENV" "$1" "${1}=${2}"
}

function separated_gopath {
    _prepare_goenv
    dest="${__my_gobase}/gopath"
    mkdir -p "$dest"
    set_goenv GOPATH "$dest"
    export GOPATH="$dest"
    export PATH="${dest}/bin:${PATH}"
}

function separated_gocache {
    dest="${__my_gobase}/gocache"
    mkdir -p "$dest"
    set_goenv GOCACHE "$dest"
}

function separated_goruntime {
    _prepare_goenv
    dl_goruntime "$1"
    export PATH="${__my_gobase}/go/bin:${PATH}"
}

function default_go_ver {
    alias go="${HOME}/golang/${1}/bin/go"
}
