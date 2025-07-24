#!/usr/bin/zsh -f
# a helper to extrct single-file bundle and wrap ostree commands, run "fpak" for help

loadlib _lib

FLATPAK_BIN="$(whence flatpak)" || echo "flatpak not found, please install flatpak"
whence flatpak-builder >/dev/null 2>&1 || echo "flatpak-builder not found, please install flatpak-builder"

function _fpak_help() {
    cat <<EOF
Usage: fpak [command] [options]

Commands:
    e|extract <sfb-file>
            Extracts a single-file bundle (SFB) as ostree repository. It will
            overwrite target directory (.rmi-work/flatpak/basename_of_sfb_file/repo)
            if exists.
    m|merge <sfb-file>
            Extracts a single-file bundle (SFB) and merges it into target directory
            (.rmi-work/flatpak/basename_of_sfb_file/repo). If the target directory
            does not exist, it is identical to 'extract'.
    commits <repo-name>
            Lists commits in the specified ostree repository. The repository
            must be a valid ostree repository.
    use <repo-name> [commit_id]
            Sets the specified commit as current version. It will try to find the
            latest commit if no commit_id is specified.
            You need jq to run this command.
    docker <repo-name> [--port <port>] [--local]
            Creates a nginx server (with docker) to serve the specified ostree
            repository. If --port is specified, it will use the specified port
            instead of the default 8080. If --local is specified, it will bind to
            loopback address (-p 127.0.0.1:port:80 instead of -p port:80).
            you need docker to run this command.
    l|ls [--full]
            Lists extracted repository. If --full is specified, it will show full
            path to the repository.
    o|ostree <repo-name> <command> [args...]
            Runs an ostree command on the specified repository. The repository
            must be a valid ostree repository.
    r|repo f|first [-f|--full]
            Just a shortcut for 'fpak l --full | head -n 1'.
    r|repo l|last [-f|--full]
            Just a shortcut for 'fpak l --full | tail -n 1'.
    r|repo n|nth <n> [-f|--full]
            Just a shortcut for 'fpak l --full | sed -n "${n}p"'.
    r|repo br|rebuild <repo-name>
            Rebuilds the specified repository. It will run 'flatpak build-update-repo'
            on the repository to generate static deltas and update the repository.
    h|help
            Displays this help message.
EOF
}

function fpak() {
    local cmd="$1"
    shift
    case "$cmd" in
        e|extract)
            _fpak_cmd_extract "$@"
            ;;
        m|merge)
            _fpak_cmd_merge "$@"
            ;;
        commits)
            _fpak_cmd_commits "$@"
            ;;
        use)
            _fpak_cmd_use "$@"
            ;;
        docker)
            _fpak_cmd_docker "$@"
            ;;
        l|ls)
            _fpak_cmd_ls "$@"
            ;;
        o|ostree)
            _fpak_cmd_ostree "$@"
            ;;
        r|repo)
            case "$1" in
                f|first)
                    shift
                    _fpak_cmd_repo_first "$@"
                    ;;
                l|last)
                    shift
                    _fpak_cmd_repo_last "$@"
                    ;;
                n|nth)
                    shift
                    _fpak_cmd_repo_nth "$@"
                    ;;
                rb|rebuild)
                    shift
                    _fpak_cmd_repo_rebuild "$@"
                    ;;
                *)
                    _fpak_help
                    ;;
            esac
            ;;
        *)
            _fpak_help
            ;;
    esac
}

function _fpak_base_path() {
    echo "${_RMI_WORK_DIR}/flatpak/${1}"
}

function _fpak_repo_path() {
    echo "$(_fpak_base_path "$1")/repo"
}

function _fpak_cmd_ostree() {
    if [[ -z "$1" ]]
    then
        _fpak_help
        return 1
    fi
    local repo_path="$(_fpak_repo_path "$1")"
    shift
    ostree --repo="$repo_path" "$@"
}

function _fpak_commit_ids() {
    (
        local repo_path="$(_fpak_repo_path "$1")"
        cd "$repo_path" || return 1
        find . -type f -name "*.commit" | while read -r commit_file
        do
            echo "$(basename "$(dirname "$commit_file")")$(basename "$commit_file" .commit)"
        done
    )
}

function _fpak_current_info() {
    local cmd="$1"
    shift
    (
        set -e
        case "$cmd" in
            name)
                fpak ostree "$1" show "$2" | grep -F Name: | cut -d ':' -f 2- | xargs
                ;;
            arch)
                fpak ostree "$1" show "$2" | grep -F Arch: | cut -d ':' -f 2- | xargs
                ;;
            branch)
                fpak ostree "$1" show "$2" | grep -F Branch: | cut -d ':' -f 2- | xargs
                ;;
            head)
                local name="$(_fpak_current_info name "$@")"
                local arch="$(_fpak_current_info arch "$@")"
                local branch="$(_fpak_current_info branch "$@")"
                echo "app/${name}/${arch}/${branch}"
                ;;
            *)
                set +e
                return 1
                ;;
        esac
    )
}

function _fpak_cmd_merge() {
    if [[ -z "$1" || ! -f "$1" ]]; then
        _fpak_help
        return 1
    fi

    local flatpak_file="$1"
    local _b_n="$(basename "$flatpak_file" .flatpak)"
    local base_name="$(echo "$_b_n" | cut -d '-' -f 1)"
    local repo_path="$(_fpak_repo_path "$base_name")"

    # create and initialize the repository if it does not exist
    local new=0
    mkdir -p "$repo_path"
    if [[ ! -f "${repo_path}/config" ]]
    then
        fpak ostree "$base_name" init --mode=archive-z2 || return 1
        new=1
    fi

    # extract the single-file bundle into the repository
    fpak ostree "$base_name" static-delta apply-offline "$flatpak_file" || return $?

    if [[ $new -eq 1 ]]
    then
        fpak use "$base_name" || return $?
    fi
}

function _fpak_cmd_extract() {
    if [[ -z "$1" || ! -f "$1" ]]; then
        _fpak_help
        return 1
    fi

    local _b_n="$(basename "$1" .flatpak)"
    local base_name="$(echo "$_b_n" | cut -d '-' -f 1)-$(echo "$_b_n" | cut -d '-' -f 3)"
    local repo_path="$(_fpak_repo_path "$base_name")"
    rm -fr "$repo_path"

    fpak merge "$1" || return $?
}

function _fpak_commit_as_info() {
    local repo_name="$1"
    local commit_id="$2"
    local repo_path="$(_fpak_repo_path "$repo_name")"
    local date="$(fpak ostree "$repo_name" show "$commit_id" | grep -F "Date:" | cut -d ':' -f 2- | xargs)"
    local name="$(fpak ostree "$repo_name" show "$commit_id" | grep -F "Name:" | cut -d ':' -f 2- | xargs)"
    local arch="$(fpak ostree "$repo_name" show "$commit_id" | grep -F "Arch:" | cut -d ':' -f 2- | xargs)"
    local branch="$(fpak ostree "$repo_name" show "$commit_id" | grep -F "Branch:" | cut -d ':' -f 2- | xargs)"

    if [[ -z "$name" || -z "$arch" || -z "$branch" ]]
    then
        return
    fi

    echo '{}' | jq -SMc "setpath([\"name\"]; \"${name}\")|
        setpath([\"arch\"]; \"${arch}\")|
        setpath([\"branch\"]; \"${branch}\")|
        setpath([\"date\"]; \"${date}\")|
        setpath([\"ref\"]; \"app/${name}/${arch}/${branch}\")|
        setpath([\"commit_id\"]; \"${commit_id}\")"
}

function _fpak_all_commit_info() {
    local repo_name="$1"
    local ret='[]'
    _fpak_commit_ids "$repo_name" | while read -r commit_id
    do
        ret="$(echo "$ret" | jq -SMC ". + [$(_fpak_commit_as_info "$repo_name" "$commit_id")]" 2>/dev/null)"
    done

    echo "$ret" | jq -SMc '.'
}

function _fpak_create_ref() {
    local repo_name="$1"
    local commit_info="$2"
    local repo_path="$(_fpak_repo_path "$repo_name")"
    local ref="$(echo "$commit_info" | jq -r '.ref')"
    local commit_id="$(echo "$commit_info" | jq -r '.commit_id')"
    mkdir -p "$(dirname "${repo_path}/refs/heads/${ref}")"
    echo "$commit_id" > "${repo_path}/refs/heads/${ref}"
}

function _fpak_cmd_commits() {
    local repo_path="$(_fpak_repo_path "$1")"
    if [[ ! -d "$repo_path" ]]; then
        _fpak_help
        return 1
    fi
    
    _fpak_commit_ids "$1" | while read -r commit_id
    do
        local info="$(fpak ostree "$1" show "$commit_id")"
        echo "$info" | grep -F "Name:" > /dev/null 2>&1 || continue

        echo "$info"
        echo
    done
}

function _fpak_cmd_use() {
    if [[ -z "$1" ]]; then
        _fpak_help
        return 1
    fi

    local repo_name="$1"
    local repo_path="$(_fpak_repo_path "$repo_name")"
    if [[ ! -d "$repo_path" ]]; then
        _fpak_help
        return 1
    fi

    local commit_id="$2"
    if [[ ! -z "$commit_id" ]]
    then
        local info="$(_fpak_commit_as_info "$repo_name" "$commit_id")"
        local ref="$(echo "$info" | jq -r '.ref')"
        local id="$(echo "$info" | jq -r '.commit_id' | cut -c -12)"
        _fpak_create_ref "$repo_name" "$info"
        echo "Ref ${ref} is pointing to commit ${id}."
        return $?
    fi

    local commits="$(_fpak_all_commit_info "$repo_name")"
    echo "$commits" | jq .
    while [[ "$(echo "$commits" | jq length)" -gt 0 ]]
    do
        local cur="$(echo "$commits" | jq -SMc '.[0]')"
        commits="$(echo "$commits" | jq -SMc '.[1:]')"
        local ref="$(echo "$cur" | jq -r '.ref')"
        local id="$(echo "$cur" | jq -r '.commit_id' | cut -c -12)"
        _fpak_create_ref "$repo_name" "$cur"
        echo "Ref ${ref} is pointing to commit ${id}."
    done
}

function _fpak_cmd_repo_rebuild() {
    if [[ -z "$1" ]]; then
        _fpak_help
        return 1
    fi

    local repo_name="$1"
    local repo_path="$(_fpak_repo_path "$repo_name")"
    if [[ ! -d "$repo_path" ]]; then
        _fpak_help
        echo
        echo "Repository '$repo_name' does not exist."
        return 1
    fi

    echo "Rebuilding repository '$repo_name' ..."
    flatpak build-update-repo --generate-static-deltas "$repo_path"
}

function _fpak_cmd_docker() {
    if [[ -z "$1" ]]; then
        _fpak_help
        return 1
    fi
    repo_name="$1"
    shift

    local repo_path="$(_fpak_repo_path "$repo_name")"
    if [[ ! -d "$repo_path" ]]; then
        _fpak_help
        return 1
    fi

    local port=8080
    local bind=''
    while [[ $# -gt 0 ]]
    do
        case "$1" in
            --port)
                shift
                port="$1"
                ;;
            --local)
                bind='127.0.0.1:'
                ;;
            *)
                break
                ;;
        esac
        shift
    done

    fpak repo rebuild "$repo_name" || return $?

    echo -n "Starting nginx server on port ${bind}${port} ..."
    local docker_id="$(docker run --rm -d \
        -p "${bind}${port}":80 \
        -v "${repo_path}:/usr/share/nginx/html:ro" \
        nginx 2>/dev/null
    )" || {
        local ret=$?
        echo "failed."
        echo "$docker_id"
        return $ret
    }
    echo "$docker_id" | cut -c -12
    
    echo
    echo "You can run the following command to access the flatpak repo:"
    echo "    flatpak remote-add --user --if-not-exists --no-gpg-verify test http://localhost:${port}"
    echo

    alias fpak-docker-stop="docker stop $(echo "$docker_id" | cut -c -12)"
    echo "To stop the nginx container, run:"
    echo "    docker stop $(echo "$docker_id" | cut -c -12)"
    echo "A special alias 'fpak-docker-stop' is created for convenience."
    echo

    alias fpak-install="flatpak install --reinstall --user test $(fpak o "${repo_name}" refs | grep -F app/ | head -n 1 | cut -d '/' -s -f 2)"
    echo "To install you app, run:"
    echo "    flatpak install --user test '$(fpak o "${repo_name}" refs | grep -F app/ | cut -d '/' -s -f 2)'"
    echo "A special alias 'fpak-install' is created for convenience."
}

function _fpak_cmd_ls() {
    local full=0
    if [[ "$1" == "--full" ]]
    then
        full=1
    fi
    
    find "${_RMI_WORK_DIR}/flatpak" -mindepth 1 -maxdepth 1 -type d \
        | while read -r repo_dir
    do
        if [[ $full -eq 1 ]]
        then
            echo "${repo_dir}/repo"
        else
            echo "$(basename "$repo_dir")"
        fi
    done
}

function _fpak_list_repo() {
    local full="--full"
    _has_arg "--full" "$@" || _has_arg "-f" "$@" || full=""
    fpak ls "$full"
}

function _fpak_cmd_repo_first() {
    _fpak_list_repo "$@" | head -n 1
}

function _fpak_cmd_repo_last() {
    _fpak_list_repo "$@" | tail -n 1
}

function _fpak_cmd_repo_nth() {
    local n="$1"
    shift
    if [[ -z "$n" || ! "$n" =~ ^[0-9]+$ ]]
    then
        _fpak_help
        return 1
    fi

    _fpak_list_repo "$@" | sed -n "${n}p"
}
