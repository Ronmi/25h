#!/usr/bin/zsh -f
#
# Currently only firefox and chrome are supported.
#
# You can customize executable path with envirinment variable:
#   - FIREFOX_PATH: Default to /usr/bin/firefox
#   - CHROME_PATH: Default to /usr/bin/google-chrome
#
# You can define hook function to run after resetting:
#   - reset_firefox_hook: for firefox
#   - reset_chrome_hook: for chrome
#
# Say you want to disable quick find key '/' by default, add following code
# in conf.zsh:
#
#   function reset_firefox_hook {
#       cat <<EOF > "${_RMI_WORK_DIR}/firefox/user.js"
#   user_pref("accessibility.typeaheadfind.manual", false);
#   EOF
#   }       

loadlib _lib

function reset_firefox {
    p="${_RMI_WORK_DIR}/firefox"
    rm -fr "$p" > /dev/null 2>&1
    mkdir -p "${_RMI_WORK_DIR}/firefox"
    cat <<EOF > "${_RMI_WORK_DIR}/firefox/user.js"
user_pref("browser.tabs.closeWindowWithLastTab", false);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.shell.skipDefaultBrowserCheckOnFirstRun", true);
user_pref("browser.shell.didSkipDefaultBrowserCheckOnFirstRun", true);
user_pref("app.update.auto", false);
EOF

    test_func reset_firefox_hook && reset_firefox_hook
}

function firefox {
    _fx=${FIREFOX_PATH:-/usr/bin/firefox}
    p="${_RMI_WORK_DIR}/firefox"
    if [[ ! -d "$p" ]]
    then
        reset_firefox
    fi
    "$_fx" --profile "$p" "$@"
}

function google-chrome {
    _ch=${CHROME_PATH:-/usr/bin/google-chrome}
    p="${_RMI_WORK_DIR}/chrome"
    if [[ ! -d "$p" ]]
    then
        reset_chrome
    fi
    "$_ch" --user-data-dir "$p" "$@"
}

function chrome {
    google-chrome "$@"
}

function reset_chrome {
    p="${_RMI_WORK_DIR}/chrome"
    rm -fr "$p" > /dev/null 2>&1
    mkdir -p "$p"
    test_func reset_chrome_hook && reset_chrome_hook
}
