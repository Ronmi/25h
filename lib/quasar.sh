#!/usr/bin/zsh -f
loadlib node

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
