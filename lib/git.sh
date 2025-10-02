#!/usr/bin/zsh -f
# some common git tasks

function _gitsync() {
    src="${GIT_SYNC_SOURCE:-source}"
    dst="${GIT_SYNC_DESTINATION:-origin}"
    branch="$1"

    git remote update
    git push "$dst" "${src}/${branch}:${branch}"
}

function gitsync() {
    _gitsync "${1:-master}"
}
