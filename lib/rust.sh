#!/usr/bin/zsh -f

# WARNING
#
# these helpers requires you to install rust toolchains using rustup with default settings

alias b="cargo build"
alias t="cargo test"
alias r="cargo run"
alias u="cargo update"
alias c="cargo clean"

################ cross build helpers

if [[ -n "$RUST_ENABLE_MUSL" ]]
then
    function muslc {
        if [[ -z $1 ]]
        then
            cargo
            return $?
        fi

        arg="$1"
        shift

        cargo "$arg" --target x86_64-unknown-linux-musl "$@"
    }
    alias mb="muslc build"
    alias mr="muslc run"

    function prepare_musl {
        rustup target add x86_64-unknown-linux-musl \
            && sudo apt update \
            && sudo apt install -y musl-tools
    }
fi

if [[ -n "$RUST_ENABLE_CROSS" ]]
then
    source "$(dirname "$(readlink -e "$0")")/docker.sh"
    
    function _cxt {
        target="$1"
        act="$2"
        shift
        shift
        cross "$act" --target "$target" "$@"
    }
    
    function arm64 {
        _cxt aarch64-unknown-linux-gnu "$@"
    }
    
    function w64 {
        _cxt x86_64-pc-windows-gnu "$@"
    }

    function arm64m {
        _cxt aarch64-unknown-linux-musl "$@"
    }
fi
