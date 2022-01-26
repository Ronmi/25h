#!/usr/bin/zsh -f

alias b="cargo build"
alias t="cargo test"
alias r="cargo run"
alias u="cargo update"
alias c="cargo clean"

################ cross build helpers

if [[ -n "$RUST_ENABLE_MUSL" ]]
then
    alias mb="cargo build --target x86_64-unknown-linux-musl"

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

    function build_w64m {
        cat <<EOF | d build -t cross-w64-msvc - 
FROM debian:stable-slim

RUN dpkg --add-architecture i386
RUN apt update && \
    apt install -y wine32 wine64-preloader wine32-preloader wine-binfmt wget curl git msitools p7zip-full unzip && \
    apt clean

WORKDIR /
RUN git clone https://github.com/est31/msvc-wine-rust xbuild
WORKDIR /xbuild
RUN ./get.sh licenses-accepted

ENV CARGO_TARGET_X86_64_PC_WINDOWS_MSVC_LINKER=/xbuild/linker-scripts/linkx64.sh
ENV CARGO_TARGET_I686_PC_WINDOWS_MSVC_LINKER=/xbuild/linker-scripts/linkx86.sh

RUN echo 'IyEvYmluL2Jhc2gKbWtkaXIgL3RtcC90bXBob21lCmV4ZWMgIiRAIg==' | base64 -d | tee /docker-entrypoint.sh
RUN chmod a+x /docker-entrypoint.sh

ENV HOME=/tmp/tmphome

ENTRYPOINT ["/docker-entrypoint.sh"]

EOF
    }

    function w64m {
        ################ prepare custom image
        d images cross-w64-msvc -q | grep -c . > /dev/null
        if [[ $? -ne 0 ]]
        then
            build_w64m
        fi

        ################ detect if we have binfmt support
        if [[ ! -f /proc/sys/fs/binfmt_misc/wine ]]
        then
            d run --rm --privileged cross-w64-msvc bash -c 'update-binfmts --import wine ; update-binfmts --enable wine'
        fi
        
        export CROSS_TARGET_X86_64_PC_WINDOWS_MSVC_IMAGE=cross-w64-msvc
        _cxt x86_64-pc-windows-msvc "$@"
    }
fi
