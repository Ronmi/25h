#!/usr/bin/zsh -f
# quasar framework (vue3) helper, depends on "node" helper

loadlib node

(
    cd "$_RMI_WORK_HERE"
    find . -name 'quasar.config.[jt]s' |grep quasar >/dev/null 2>&1 || echo "No Quasar project found in the current directory. Please run 'create_quasar' to set up a new project."
)

function install_tool {
    NODE_PM add -D @quasar/cli @quasar/icongenie
}

function create_quasar() {
    NODE_PM create quasar@latest || return $?
    install_tool
}

function quasar {
    npx quasar "$@"
}

function icongenie {
    npx icongenie "$@"
}

function quasar_test {
    if [[ $# -eq 0 ]]
    then
        NODE_PM test
        return $?
    fi

    if [[ "$1" == "help" ]]
    then
        echo
        echo "Usage: quasar_test [args...]"
        echo
        echo "  Running 'quasar_test unit ui' equals to 'NODE_PM test:unit:ui'"
        echo "  where 'NODE_PM' is one of pnpm or yarn."
	return 0
    fi
    local original_args=("$@")
    local joined_string="${(j.:.)original_args}"

    NODE_PM run "test:${joined_string}"
}

alias qb="quasar build"
alias qba="quasar build -m capacitor -T android"
alias qt="quasar_test"
