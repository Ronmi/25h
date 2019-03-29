#!/usr/bin/zsh -f

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

function separated_gopath {
    export GOPATH="${_RMI_WORK_HERE}/.rmi-work/gopath"
    mkdir -p "$GOPATH"
}

function default_go_ver {
    alias go="${HOME}/golang/${1}/bin/go"
}
