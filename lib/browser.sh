#!/usr/bin/zsh -f

function firefox {
    _fx=${FIREFOX_PATH:-/usr/bin/firefox}
    p="${_RMI_WORK_DIR}/firefox"
    mkdir -p "$p"
    "$_fx" --profile "$p" "$@"
}

function reset_firefox {
    rm -fr "${_RMI_WORK_DIR}/firefox" > /dev/null 2>&1
}

function google-chrome {
    _ch=${CHROME_PATH:-/usr/bin/google-chrome}
    p="${_RMI_WORK_DIR}/chrome"
    mkdir -p "$p"
    "$_ch" --user-data-dir "$p" "$@"
}

function chrome {
    google-chrome "$@"
}

function reset_chrome {
    rm -fr "${_RMI_WORK_DIR}/chrome" > /dev/null 2>&1
}
