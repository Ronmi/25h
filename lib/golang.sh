#!/usr/bin/zsh -f
# golang helpers to run some command faster, run "g" for help

loadlib _lib
_go_cmd="${_go_cmd_name:-g}"
_set_helper "$_go_cmd" Golang _run_go_cmd

function _go_helper_usage() {
    cat <<EOF
Usage: ${_go_cmd} [command] [args]

Available commands:
    c|coverhtml
            Generate HTML coverage report
    coverfunc
            Generate function coverage report
    b|bench
            Run benchmarks
    benchsome [filter]
            Run benchmarks matching the filter
    d|doc [--force-update|-u]
            Start a local documentation server for Go packages. It installs pkgsite
            if not already installed. You can use --force-update or -u to force
            updating pkgsite to the latest version.
    t|test [filter]
            Run tests matching the filter
EOF
}

function _run_go_cmd() {
    case "$1" in
        c|coverhtml)
            shift
            _go_cmd_coverhtml "$@"
            return $?
            ;;
        coverfunc)
            shift
            _go_cmd_coverfunc "$@"
            return $?
            ;;
        b|bench)
            shift
            _go_cmd_bench "$@"
            return $?
            ;;
        benchsome)
            shift
            _go_cmd_benchsome "$@"
            return $?
            ;;
        d|doc)
            shift
            _go_cmd_doc "$@"
            return $?
            ;;
        t|test)
            shift
            _go_cmd_test "$@"
            return $?
            ;;
        *)
            _go_helper_usage
            return 1
    esac
}

function _go_cmd_coverhtml {
    cover="${_RMI_WORK_DIR}/go.coverage"
    go test -coverprofile="${cover}" "$@" \
        && go tool cover -html="${cover}"
}

function _go_cmd_coverfunc {
    cover="${_RMI_WORK_DIR}/go.coverage"
    go test -coverprofile="${cover}" "$@" \
        && go tool cover -func="${cover}"
}

function _go_cmd_bench {
    _go_cmd_benchsome . "$@"
}

function _go_cmd_benchsome {
    go test -benchmem -bench "$@"
}

function _go_cmd_doc {
    local force_update=1
    _has_arg --force-update "$@" || _has_arg -u "$@" || force_update=0
    which pkgsite > /dev/null 2>&1
    if [[ $? != 0 || $force_update -eq 1 ]]
    then
        go install golang.org/x/pkgsite/cmd/pkgsite@latest || retrun $?
    fi

    pkgsite -cache -http :8089 -gorepo=~/gosrc "${_RMI_WORK_HERE}"
}

function _go_cmd_test {
    go test -run "$@"
}

find "${_RMI_WORK_HERE}" -name go.mod | grep -F go.mod > /dev/null 2>&1 || \
    echo "You have not set up your Go workspace yet. Please run 'go mod init' in your project directory."
