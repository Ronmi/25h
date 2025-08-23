#!/usr/bin/zsh -f
# ai shortcuts, including helpers to install useful MCP servers

loadlib node
loadlib _lib

_ai_cmd="${_ai_cmd_name:=ai}"
_set_helper "$_ai_cmd" AI _run_ai_cmd

function _ai_helper_usage() {
    cat <<USAGE1
Usage: ${_ai_cmd} [options] <command> [args...]

Available commands:
    gp
            Run 'gemini -m gemini-2.5-pro'
    gs
            Run 'gemini -m gemini-2.5-flash'
    cp
            Run 'claude --model opus'
    cs
            Run 'claude --model sonnet'
    c
            Run 'codex' with mcp servers defined in .mcp.json (if any)
    use server-preset-name
            Create project-local settings with specified MCP server.

            Supported server presets:
                gopls: language server with go
                rust: language server with rust (rust-analyzer)
                tsls: language server with typescript (typescript-language-server)
                pyright: language server with python (pyright-langserver)
USAGE1

    find "${HOME}/.zsh.d/lib/local" -name "_ai.*.sh" -type f,l | while read -r fn
    do
        local name="$(echo "$fn" | xargs basename | cut -d '.' -f 2)"
        local desc="$(source "$fn" && ai_mcp_desc)"
        echo "                ${name}: ${desc}"
    done

cat <<USAGE2
    help
            Show this help message

Running this helper with unsupported command (or without command) will default to:
    claude <args you provided ...>

USAGE2
}

function _ai_helper_merge_config() {
    local destf="$1"
    mkdir -p "$(dirname "$destf")"
    if [[ ! -f "$destf" ]]
    then
        echo '{}' > "$destf"
    fi

    local srcf="$(mktemp -t XXXXXXX.json)"
    local desttmp="$(mktemp -t XXXXXXX.json)"
    cat /dev/stdin > "$srcf"

    jq -M --slurpfile b "$srcf" '($b[0] | keys[0]) as $b_key | if .mcpServers? | has($b_key) then . else . * {mcpServers: ((.mcpServers // {}) + $b[0])} end' "$destf" > "$desttmp"

    if [[ $? -ne 0 ]]
    then
        rm -f "$srcf" "$desttmp"
        return 1
    fi
    mv "$desttmp" "$destf"
    rm -f "$srcf"
}

function _ai_helper_set_claude() {
    local destf="${_RMI_WORK_HERE}/.mcp.json"
    cat /dev/stdin | _ai_helper_merge_config "$destf" || \
        {
            echo "Failed to update Claude settings."
            return 1
        }
}

function _ai_helper_set_gemini() {
    local destf="${_RMI_WORK_HERE}/.gemini/settings.json"
    cat /dev/stdin | _ai_helper_merge_config "$destf" || \
        {
            echo "Failed to update Gemini settings."
            return 1
        }
}

function _ai_helper_use_local_formatter() {
    echo '{'
    echo "$1" | jq . -RcM
    echo ':'
    echo "$2"
    echo '}'
}

function _ai_helper_use_local() {
    local fn="${HOME}/.zsh.d/lib/local/_ai.${1}.sh"
    echo "Applying MCP server config defined in $fn ... "
    if [[ ! -f "$fn" ]]
    then
        return 1
    fi

    (source "$fn" && ai_mcp_prepare) || return $?

    local name="$1"
    shift
    local desc="$(source "$fn" && ai_mcp_desc)"
    local claude="$(source "$fn" && ai_mcp_conf_claude "$@")"
    local gemini="$(source "$fn" && ai_mcp_conf_gemini "$@")"

    [[ -n "$claude" ]] \
        && _ai_helper_use_local_formatter "$name" "$claude" \
            | _ai_helper_set_claude || return $?
    [[ -n "$gemini" ]] \
        && _ai_helper_use_local_formatter "$name" "$gemini" \
            | _ai_helper_set_gemini || return $?
}

function _ai_helper_use_langserver_build_args() {
    local name="$1"
    shift

    echo '{'
    echo "$name" | jq . -RcM
    echo ':{"command": "mcp-language-server", "args": '

    _args_to_json \
        "--workspace" \
        "$_RMI_WORK_HERE" \
        "--lsp" \
        "$@"

    echo '}}'
}

function _ai_helper_use_langserver() {
    local conf="$(_ai_helper_use_langserver_build_args "$@")"

    echo "$conf" | _ai_helper_set_claude || return $?
    echo "$conf" | _ai_helper_set_gemini || return $?
}

function _ai_helper_use_gopls() {
    # test if required tools are installed
    _has_prog gopls || {
        _confirm "Install gopls?" \
            && go install golang.org/x/tools/gopls@latest >/dev/null 2>&1 \
                || return $?
    }
    _has_prog mcp-language-server || {
        _confirm "Install mcp-language-server?" \
            && go install github.com/isaacphi/mcp-language-server@latest >/dev/null 2>&1 \
                || return $?
    }

    _ai_helper_use_langserver gopls gopls
}

function _ai_helper_use_rust_analyzer() {
    _has_prog rust-analyzer || {
        _confirm "Install rust-analyzer?" \
            && rustup component add rust-analyzer >/dev/null 2>&1 \
                || return $?
    }

    _ai_helper_use_langserver rust-analyzer rust-analyzer
}

function _ai_helper_use_tsls() {
    _has_prog typescript-language-server || {
        _confirm "Install typescript-language-server?" \
            && npm install -g typescript-language-server >/dev/null 2>&1 \
                || return $?
    }

    _ai_helper_use_langserver tsls typescript-language-server
}

function _ai_helper_use_pyright() {
    _has_prog pyright-langserver || {
        _confirm "Install pyright?" \
            && npm install -g pyright-langserver >/dev/null 2>&1 \
                || return $?
    }

    _ai_helper_use_langserver pyright pyright-langserver -- --stdio
}

function _ai_helper_check_codex() {
    _has_prog codex || {
        echo -n 'Installing Codex CLI ... '
        _download_latest_release_from_github openai codex codex-x86_64-unknown-linux-gnu.tar.gz -O - | tar xzf - -C "${HOME}/bin/" && mv "${HOME}/bin/codex-x86_64-unknown-linux-gnu" "${HOME}/bin/codex"
        if [[ $? -ne 0 ]]
        then
            echo 'failed.'
            echo
            echo "Failed to install Codex CLI. Please install the Codex CLI manually."
            return 1
        fi
        echo "done."
    }
}

function _ai_helper_check_gemini() {
    which gemini >/dev/null 2>&1 && return 0
    echo -n 'Installing Gemini CLI ... '
    NODEPM install -g @google/gemini-cli > /dev/null 2>&1
    if [[ $? -ne 0 ]]
    then
        echo 'failed.'
        echo
        echo "Failed to install Gemini CLI. Please install the Gemini CLI manually."
        return 1
    fi
    echo "done."
}

function _ai_helper_check_claude_code() {
    which claude >/dev/null 2>&1 && return 0
    echo -n 'Installing Claude CLI ... '
    NODEPM install -g @anthropic/claude-cli > /dev/null 2>&1
    if [[ $? -ne 0 ]]
    then
        echo 'failed.'
        echo
        echo "Failed to install Claude Code. Please install the Claude Code manually."
        return 1
    fi
    echo "done."
}

# claude has some trouble when running shell command with my zsh setup
function _ai_helper_exec() {
    SHELL="$(which bash)" "$@"
}

function _run_ai_cmd() {
    if [[ $# -lt 1 ]]
    then
        _ai_helper_usage
        return 1
    fi

    local cmd="$1"
    shift
    case "$cmd" in
        c)
            _ai_helper_check_codex || return 1
            codex -c "mcp_servers=$(jq .mcpServers "${_RMI_WORK_HERE}/.mcp.json" -cM | sed 's/":/"=/g')" "$@"
            ;;
        gp)
            _ai_helper_check_gemini || return 1
            _ai_helper_exec gemini -m gemini-2.5-pro "$@"
            ;;
        gs)
            _ai_helper_check_gemini || return 1
            _ai_helper_exec gemini -m gemini-2.5-flash "$@"
            ;;
        cs)
            _ai_helper_check_claude_code || return 1
            _ai_helper_exec claude --model sonnet "$@"
            ;;
        cp)
            _ai_helper_check_claude_code || return 1
            _ai_helper_exec claude --model opus "$@"
            ;;
        use)
            if [[ $# -lt 1 ]]
            then
                _ai_helper_usage
                return 1
            fi
            case "$1" in
                gopls)
                    _ai_helper_use_gopls || return $?
                    ;;
                rust)
                    _ai_helper_use_rust_analyzer || return $?
                    ;;
                tsls)
                    _ai_helper_use_tsls || return $?
                    ;;
                pyright)
                    _ai_helper_use_pyright || return $?
                    ;;
                *)
                    local fn="${HOME}/.zsh.d/lib/local/_ai.${1}.sh"
                    if [[ -f "$fn" ]]
                    then
                        _ai_helper_use_local "$@" && echo "${1} has been configured."
                        return $?
                    else
                        _ai_helper_usage
                        return 1
                    fi
                    ;;
            esac
            ;;
        help)
            _ai_helper_usage
            return 1
            ;;
        *)
            _ai_helper_check_claude_code || return 1
            _ai_helper_exec claude "$cmd" "$@"
            ;;
    esac
}


###### completions for the helper

function _ai_helper_completions() {
    if (( CURRENT == 2 )); then
        local -a commands
        commands=(
            'c:Run Codex with MCP servers defined in .mcp.json'
            'gp:Run Gemini 2.5 Pro'
            'gs:Run Gemini 2.5 Flash'
            'cs:Run Claude Sonnet'
            'cp:Run Claude Opus'
            'use:Add mcp server to project'
            'help:Show this help message'
        )
        _describe -t commands "AI Commands" commands
        return 0
    fi

    if (( CURRENT == 3 )) && [[ "${words[2]}" == "use" ]]; then
        local -a use_commands
        use_commands=(
            'gopls:Use language server for Go (gopls)'
            'rust:Use language server for Rust (rust-analyzer)'
            'tsls:Use language server for TypeScript (typescript-language-server)'
            'pyright:Use language server for Python (pyright-langserver)'
        )
        find "${HOME}/.zsh.d/lib/local" -name "_ai.*.sh" -type f,l | while read -r fn
        do
            local name="$(echo "$fn" | xargs basename | cut -d '.' -f 2)"
            local desc="$(source "$fn" && ai_mcp_desc)"
            use_commands+=("${name}:${desc}")
        done
        _describe -t use-commands "Use Commands" use_commands
        return 0
    fi

    return 1
}

compdef _ai_helper_completions $_ai_cmd
