#!/usr/bin/zsh -f
# setup basic Android environment variables

export ANDROID_HOME="${HOME}/Android/Sdk"
export ANDROID_SDK_ROOT="${ANDROID_HOME}"
export PATH="${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:${PATH}"

function android_build_tool() {
    sdkver="$(ls "${ANDROID_HOME}/build-tools"|grep -E '^[0-9]+\.[0-9]+\.[0-9]+$'|sort -r|head -n 1)"
    cmd="$1"
    shift

    "${ANDROID_HOME}/build-tools/${sdkver}/${cmd}" "$@"
}
