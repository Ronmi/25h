#!/usr/bin/zsh -f

export ANDROID_SDK_ROOT="${HOME}/Android/Sdk"
export PATH="${PATH}:${ANDROID_SDK_ROOT}/tools:${ANDROID_SDK_ROOT}/platform-tools"

if [[ -d "${ANDROID_SDK_ROOT}/build-tools" ]]
then
    latest="$(/bin/ls "${ANDROID_SDK_ROOT}/build-tools"|grep -E '^[0-9]+\.[0-9]+\.[0-9]+$'|sort -r|head -n 1)"
    export PATH="${PATH}:${ANDROID_SDK_ROOT}/build-tools/${latest}"
fi

function signapk {
    if [[ ! -f dist/capacitor/android/apk/release/app-release-unsigned.apk ]]
    then
        echo 'Invalid path, "dist/capacitor/android/apk/release/app-release-unsigned.apk" not found'
        return 1
    fi

    apksigner sign --in dist/capacitor/android/apk/release/app-release-unsigned.apk --out "$2" --ks "$1"
}
