#!/usr/bin/zsh -f
# quasar framework (vue3) helper, depends on "node" helper

loadlib node

find . -name 'quasar.config.js' |grep quasar >/dev/null 2>&1 || echo "No Quasar project found in the current directory. Please run 'create_quasar' to set up a new project."

function install_tool {
    NODE_PM add --dev @quasar/cli @quasar/icongenie
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


alias qb="quasar build"
alias qba="quasar build -m capacitor -T android"
