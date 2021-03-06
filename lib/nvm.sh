#!/usr/bin/zsh -f

# install nvm
function install_nvm {
    git clone https://github.com/creationix/nvm.git "${NVM_DIR}"
    cd "${NVM_DIR}"
    git checkout "$(git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1))"
}
