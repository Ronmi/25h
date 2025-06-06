#!/usr/bin/zsh -f
# golang helpers to run some command faster

loadlib _lib

function coverhtml {
    cover="${_RMI_WORK_DIR}/go.coverage"
    go test -coverprofile="${cover}" "$@" \
        && go tool cover -html="${cover}"
}

function coverfunc {
    cover="${_RMI_WORK_DIR}/go.coverage"
    go test -coverprofile="${cover}" "$@" \
        && go tool cover -func="${cover}"
}

function bench {
    benchsome . "$@"
}

function benchsome {
    go test -benchmem -bench "$@"
}

function doc {
    which pkgsite > /dev/null 2>&1
    if [[ $? != 0 ]]
    then
        set -e
        (cd ; go install golang.org/x/pkgsite/cmd/pkgsite@latest)
        set +e
    fi

    set -x
    pkgsite -cache -http :8089 -gorepo=~/gosrc "${_RMI_WORK_HERE}"
    set +x
}

function trun {
    go test -run "$@"
}
