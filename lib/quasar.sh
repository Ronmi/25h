#!/usr/bin/zsh -f
# quasar framework (vue3) helper, depends on "node" helper, run "quasar" for help

loadlib _lib
loadlib node

_quasar_cmd="${_quasar_cmd_name:=quasar}"
_set_helper "$_quasar_cmd" Quasar _run_quasar_cmd

function _quasar_helper_usage() {
    cat <<EOF
Usage: ${_quasar_cmd} [command] [args...]

Available commands:
    init
            Create a new Quasar project
    it|install-tool
            Install Quasar CLI and IconGenie as dev dependencies
    icongenie [args...]
            Run IconGenie commands
    t|test [args...]
            Run Quasar tests. Running 'q test unit ci' is equivalent to
            'npm test:unit:ci' (or pnpm/yarn, depending on your setup).
    b [args...]
            Build Quasar app
    b a [args...]
            Build Android app with Capacitor
    b e [args...]
            Build Electron app
    b x [args...]
            Build Browser Extension (BEX)
    b p [args...]
            Build Progressive Web App (PWA)
    b s [args...]
            Build Server-Side Rendered (SSR) app
    [args...]
            Passes all arguments to the 'quasar' command
EOF
}

function _quasar() {
    NODE_PM exec quasar "$@"
}

function _run_quasar_cmd() {
    local cmd="$1"
    if [[ -z "$cmd" ]]
    then
        _quasar_helper_usage
        return 0
    fi
    shift
    case "$cmd" in
        init)
            _quasar_cmd_init "$@"
            ;;
        it|install-tool)
            _quasar_cmd_install_tool "$@"
            ;;
        icongenie)
            NODE_PM exec icongenie "$@"
            ;;
        t|test)
            _quasar_cmd_test "$@"
            ;;
        b)
            local sub_cmd="$1"
            if [[ $# -gt 0 ]]
            then
                shift
            fi
            case "$sub_cmd" in
                a)
                    _quasar build -m capacitor -T android "$@"
                    ;;
                e)
                    _quasar build -m electron "$@"
                    ;;
                x)
                    _quasar build -m bex "$@"
                    ;;
                p)
                    _quasar build -m pwa "$@"
                    ;;
                s)
                    _quasar build -m ssr "$@"
                    ;;
                *)
                    _quasar build "$sub_cmd" "$@"
                    ;;
            esac
            ;;
        --)
            _quasar "$@"
            ;;
        *)
            _quasar "$cmd" "$@"
            ;;
    esac
}

function _quasar_cmd_install_tool() {
    NODE_PM add -D @quasar/cli @quasar/icongenie
}

function _quasar_cmd_init() {
    NODE_PM create quasar@latest || return $?
    _quasar_cmd_install_tool
}

function _quasar_cmd_test {
    if [[ $# -eq 0 ]]
    then
        NODE_PM test
        return $?
    fi

    local original_args=("$@")
    local joined_string="${(j.:.)original_args}"

    NODE_PM run "test:${joined_string}"
}

(
    cd "$_RMI_WORK_HERE"
    find . -name 'quasar.config.[jt]s' |grep quasar >/dev/null 2>&1 || echo "No Quasar project found in the current directory. Please run 'create_quasar' to set up a new project."
)
