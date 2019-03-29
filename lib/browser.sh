#!/usr/bin/zsh -f

_fx=${FIREFOX_PATH:-/usr/bin/firefox}
_ch=${CHROME_PATH:-/usr/bin/google-chrome}

function firefox {
    p="${_RMI_WORK_HERE}/.rmi_work/firefox"
    mkdir -p "$p"
    $_fx --profile "$p" "$@"
}

function google-chrome {
    p="${_RMI_WORK_HERE}/.rmi_work/firefox"
    mkdir -p "$p"
    $_ch --user-data-dir "$p" "$@"
}

function chrome {
    google-chrome "$@"
}
