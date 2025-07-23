#!/usr/bin/zsh -f
# a helper to extrct single-file bundle and wrap ostree commands, run "fpak" for help

FLATPAK_BIN="$(whence flatpak)" || echo "flatpak not found, please install flatpak"
whence flatpak-builder >/dev/null 2>&1 || echo "flatpak-builder not found, please install flatpak-builder"

function fpak() {
    case "$1" in
        "")
            echo "Usage: fpak [ex|extract|o|ostree|fake-repo|flatpak command] [args]"
            echo
            echo "Example:"
            echo "  fpak ex               # show usage of command extract"
            echo "  fpak ostree           # show usage of command ostree"
            echo "  fpak fake-repo        # show usage of command fake-repo"
            echo "  # flatpak commands"
            echo "  fpak install --user <path-to-flatpak-file>"
            echo "  fpak --help           # same as 'flatpak --help'"
            echo
            echo "There are three additional helpers:"
            echo
            echo "  first_fpak_repo  - same as 'fpak ex ls | head -n 1'"
            echo "  last_fpak_repo   - same as 'fpak ex ls | tail -n 1'"
            echo "  nth_fpak_repo N  - same as 'fpak ex ls | sed -n 'Np'"
            echo
            echo 'Example usage:'
            echo '    fpak o "$(first_fpak_repo)" refs'
            echo '    ostree --repo="$(nth_fpak_repo 1 --full)" refs'
            return 0
            ;;
        fake-repo)
            shift
            case "$1" in
                build)
                    shift
                    _fpak_fakerepo_build "$@"
                    ;;
                docker)
                    shift
                    _fpak_fakerepo_docker "$@"
                    ;;
                *)
                    echo "Usage: fpak fake-repo <build|docker> [args]"
                    echo
                    echo "Pass no argument like 'fpak fake-repo build' to see usage of subcommands."
                    return 0
                    ;;
            esac
            ;;
        o|ostree)
            shift
            local repo_dir="${_RMI_WORK_DIR}/flatpak/${1}/repo"
            if [[ "$1" == -h  || "$1" == --help ]]
            then
                echo "Usage: fpak o|ostree <repo-name> <ostree command> [ostree args]"
                echo
                echo "run 'fpak ex ls' to list available flatpak repos"
                return 0
            fi
            if [[ ! -d "$repo_dir" ]]
            then
                echo "No flatpak repo found, please extract a flatpak file first."
                echo
                echo "run 'fpak ex ls' to list available flatpak repos"
                return 1
            fi
            shift
            ostree --repo="$repo_dir" "$@"
            ;;
        ex|extract)
            shift
            case "$1" in
                repo)
                    shift
                    _fpak_ex_repo "$@"
                    ;;
                file)
                    shift
                    _fpak_ex_file "$@"
                    ;;
                ls)
                    shift
                    _fpak_ex_ls "$@"
                    ;;
                *)
                    echo "Usage: flatpak ex|extract <command> [args]"
                    echo
                    echo "Available commands:"
                    echo "  repo <path-to-flatpak-file>  - Extract flatpak repo from file"
                    echo "  file <path-to-flatpak-file>  - Extract flatpak file to directory"
                    echo "  ls [--full]                  - List extracted flatpak repos"
                    echo "                                   --full: show full path"
                    return 0
                    ;;
            esac
            ;;
        *)
            "$FLATPAK_BIN" "$@"
            ;;
        esac
}

function _fpak_fakerepo_build() {
    local repo_dir="${_RMI_WORK_DIR}/flatpak/${1}/repo"
    if [[ -z "$1" || ! -d "$repo_dir" ]]; then
        echo "Helper for running 'flatpak build-update-repo'"
        echo 
        echo "Usage: fpak fake-repo build <repo-name>"
        return 1
    fi
    flatpak build-update-repo --generate-static-deltas "$repo_dir"
}

function _fpak_fakerepo_docker() {
    which docker >/dev/null 2>&1 || {
        echo "docker not found, please install docker"
        return 1
    }

    local port="8080"
    local repo_name=""
    local localhost_only=""

    if [[ -z "$1" ]];
    then
        echo "Usage: fpak fake-repo docker [-p|--port <port>] [-l|--localhost-only] <-r|--repo repo-name>"
        echo
        echo "Default port is 8080."
        echo "If --localhost-only is specified, the repo will only be accessible from localhost."
        return 1
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--port)
                shift
                if [[ -z "$1" || ! "$1" =~ ^[0-9]+$ ]]; then
                    echo "Invalid port number: $1"
                    return 1
                fi
                port="$1"
                ;;
            -r|--repo)
                shift
                repo_name="$1"
                ;;
            -l|--localhost-only)
                localhost_only="127.0.0.1:"
                ;;
            *)
                echo "Usage: fpak fake-repo docker [-p|--port <port>] [-l|--localhost-only] <-r|--repo repo-name>"
                echo
                echo "Default port is 8080."
                echo "If --localhost-only is specified, the repo will only be accessible from localhost."
                return 1
                ;;
        esac
        shift
    done
    
    local repo_dir="${_RMI_WORK_DIR}/flatpak/${repo_name}/repo"
    if [[ ! -d "$repo_dir" ]]; then
        echo "Flatpak repo '$repo_name' not found in ${_RMI_WORK_DIR}/flatpak/"
        echo
        echo "Run 'fpak ex ls' to list available flatpak repos."
        return 1
    fi
    
    # _fpak_fakerepo_build "$repo_name" || {
    #     echo "Failed to run 'fpak fake-repo build ${repo_name}'"
    #     return $?
    # }
    local app_name="$(fpak o "${repo_name}" refs | grep -F app/ | cut -d '/' -s -f 2)"

    echo
    echo
    echo -n "Starting nginx in background ... "
    local docker_id="$(docker run --rm -d \
        -v "${repo_dir}:/usr/share/nginx/html:ro" \
        -p "${localhost_only}${port}:80" \
        nginx)" || {
        echo 
        echo "Failed to start nginx container."
        return 1
    }
    echo "done."

    echo
    echo "You can run the following command to access the flatpak repo:"
    echo "  flatpak remote-add --user --if-not-exists --no-gpg-verify test http://localhost:${port}"
    echo

    alias fpak-docker-stop="docker stop $(echo "$docker_id" | cut -c -12)"

    echo "To stop the nginx container, run:"
    echo "  docker stop $(echo "$docker_id" | cut -c -12)"
    echo "A special alias 'fpak-docker-stop' is created for convenience."
    echo
    echo "To install you app, run:"
    echo "  flatpak install --user test '$(fpak o "${repo_name}" refs | grep -F app/ | cut -d '/' -s -f 2)'"
    
}

function _fpak_ex_ls() {
    local base_dir="${_RMI_WORK_DIR}/flatpak"
    if [[ ! -d "$base_dir" ]]; then
        echo "No flatpak files extracted yet."
        return 0
    fi
    local opt="$1"

    find "$base_dir" -mindepth 2 -maxdepth 2 -type d -name "repo" | while read -r repo; do
        if [[ "$opt" == "--full" ]]; then
            echo "$repo"
            continue
        fi
        echo "$(basename "$(dirname "$repo")")"
    done
}

function _fpak_ex_repo() {
    if [[ -z "$1" || ! -f "$1" ]]; then
        echo "Usage: flatpak extract repo <path-to-flatpak-file>"
        return 1
    fi

    local flatpak_file="$1"
    local base_name="$(basename "$flatpak_file" .flatpak)"
    local base_dir="${_RMI_WORK_DIR}/flatpak/${base_name}"
    local repo_dir="${base_dir}/repo"

    rm -fr "$repo_dir" > /dev/null 2>&1
    mkdir -p "$repo_dir"
    ostree init --repo="$repo_dir" --mode=archive-z2
    ostree static-delta apply-offline --repo="$repo_dir" "$flatpak_file"
    (
        cd "$repo_dir"
        ls objects/*/*.commit
    ) | \
        cut -d '/' -f2-3 -s | \
        sed 's#/##' | \
        sed 's/\.commit$//' \
            > "${repo_dir}/refs/heads/fake"

    local info="$(fpak o "${base_name}" show fake)"
    local name="$(echo "$info" | grep -F Name: | cut -d ':' -f2 | xargs)"
    local arch="$(echo "$info" | grep -F Arch: | cut -d ':' -f2 | xargs)"
    local branch="$(echo "$info" | grep -F Branch: | cut -d ':' -f2 | xargs)"
    mkdir -p "${repo_dir}/refs/heads/app/${name}/${arch}"
    cp "${repo_dir}/refs/heads/fake" "${repo_dir}/refs/heads/app/${name}/${arch}/${branch}"
    
    echo "Flatpak repo ${repo_dir} created from $flatpak_file"
    echo "run 'fpak o \"${base_name}\" refs' to see available refs."
}

function _fpak_ex_file() {
    if [[ -z "$1" || ! -f "$1" ]]; then
        echo "Usage: flatpak extract file <path-to-flatpak-file>"
        return 1
    fi

    local flatpak_file="$1"
    local base_dir="${_RMI_WORK_DIR}/flatpak/$(basename "$flatpak_file" .flatpak)"
    local repo_dir="${base_dir}/repo"
    local dest_dir="${base_dir}/extracted"

    if [[ ! -d "$repo_dir" ]]; then
        _extract_flatpak_repo "$flatpak_file" || return $?
    fi

    rm -fr "$dest_dir" > /dev/null 2>&1
    ostree --repo="$repo_dir" checkout -U fake "$dest_dir"
    echo "Extracted $flatpak_file to $dest_dir"
}

function first_fpak_repo() {
    fpak ex ls "$@"| head -n 1
}

function last_fpak_repo() {
    fpak ex ls "$@"| tail -n 1
}

function nth_fpak_repo() {
    local n="$1"
    shift
    fpak ex ls "$@"| sed -n "${n}p"
}
