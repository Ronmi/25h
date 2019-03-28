#!/usr/bin/zsh -f

fx=${FIREFOX_PATH:-/usr/bin/firefox}
ch=${CHROME_PATH:-/usr/bin/google-chrome}

function firefox {
    p="${_RMi_WORK_HERE}/.rmi_work/firefox"
    mkdir -p "$p"
    $cmd --profile "$p" "$@"
}

function google-chrome {
    p="${_RMi_WORK_HERE}/.rmi_work/firefox"
    mkdir -p "$p"
    $cmd --user-data-dir "$p" "$@"
}

function chrome {
    google-chrome "$@"
}
