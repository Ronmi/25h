#!/usr/bin/zsh -f

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
