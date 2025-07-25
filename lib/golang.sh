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
    it|install-tools [-a|--all]
            Install common tools globally, like gopls, protogen, ...
            Passing -a or --all will not show confirmation.
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
        it|install-tools)
            _go_cmd_install_tools "$@"
            return $?
            ;;
        *)
            _go_helper_usage
            return 1
    esac
}

function _go_helper_install_tool() {
    if [[ $all -eq 1 ]]
    then
        echo -n "Installing ${1} ... "
        local output="$(go install "${1}@latest" 2>&1)"
        ret=$?
        if [[ $ret -eq 0 ]]
        then
            echo "done."
        else
            echo "failed."
            echo "$output"
            echo
            echo
        fi
        
        return $ret
    fi
    
    _confirm "Install ${1}?" && {
        go install "${1}@latest"
        return $?
    } || return 0
}

function _go_cmd_install_tools() {
    local all=1
    _has_arg -a "$@" || _has_arg --all "$@" || all=0
    (
        set -e
        _go_helper_install_tool github.com/charmbracelet/gum
        _go_helper_install_tool google.golang.org/grpc/cmd/protoc-gen-go-grpc
        _go_helper_install_tool golang.org/x/tools/gopls
        _go_helper_install_tool github.com/spf13/cobra-cli
        
        for i (callgraph deadcode goimports gomvpkg stringer)
        do
            _go_helper_install_tool "golang.org/x/tools/cmd/${i}"
        done
    )
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
