#!/usr/bin/zsh -f
# rust helpers

# WARNING
#
# these helpers requires you to install rust toolchains using rustup with default settings

alias b="cargo build"
alias t="cargo test"
alias r="cargo run"
alias u="cargo update"
alias c="cargo clean"

# set default cargo target dir
export CARGO_TARGET_DIR="${_RMI_WORK_DIR}/cargo-build"

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

function cover {
    (
        set -e
        name="$(grep name Cargo.toml|cut -d '"' -f 2)"
        export CARGO_INCREMENTAL=0
        export RUSTFLAGS="-Zprofile -Ccodegen-units=1 -Copt-level=0 -Clink-dead-code -Coverflow-checks=off -Zpanic_abort_tests -Cpanic=abort"
        export RUSTDOCFLAGS="-Cpanic=abort"
        set +e
        rm -fr default.profraw target/debug/coverage "./target/debug/deps/${name}"* "./target/debug/deps/lib${name}"*
        set -e

        cargo +nightly build
        cargo +nightly test "$@"
        grcov . -s . --binary-path ./target/debug/ -t html --branch --ignore-not-existing -o ./target/debug/coverage/ --excl-start 'nocover! ' --excl-stop '}} //end'
    )
}

find "${_RMI_WORK_DIR}" -name Cargo.toml | grep -F Cargo.toml > /dev/null 2>&1 || \
    echo "You have not set up your Rust workspace yet. Please run 'cargo init' or 'cargo new' in your project directory."
