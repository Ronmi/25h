#!/usr/bin/zsh -f
# ai shortcuts

loadlib node
loadlib _lib

_ai_cmd="${_ai_cmd_name:=ai}"
_set_helper "$_ai_cmd" AI _run_ai_cmd

function _ai_helper_usage() {
    cat <<USAGE
Usage: ${_ai_cmd} [options] <command> [args...]

Available commands:
    c, claude
            Run 'claude'
    g, gemini
            Run 'gemini'
    d, codex
            Run 'codex'
    help
            Show this help message

Running this helper with unsupported command (or without command) will default to:
    claude <args you provided ...>

USAGE
}

function _ai_helper_check_codex() {
    _has_prog codex || {
        echo -n 'Installing Codex CLI ... '
        local tri="$(uname -m)-$(uname -p)-$(uname -s)"
        tri="$(echo "$tri" | tr '[:upper:]' '[:lower:]')"
        _download_latest_release_from_github openai codex "codex-${tri}-gnu.tar.gz" -O - | tar xzf - -C "${HOME}/bin/" && mv "${HOME}/bin/codex-${tri}-gnu" "${HOME}/bin/codex"
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
    echo -n 'Installing Claude Code ... '
    curl -fsSL https://claude.ai/install.sh | bash > /dev/null 2>&1
    if [[ $? -ne 0 ]]
    then
        echo 'failed.'
        echo
        echo "Failed to install Claude Code. Please install it manually: https://claude.ai/install.sh"
        return 1
    fi
    echo "done."
}

# claude/gemini/codex have trouble when running shell command with my zsh setup
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
        c|claude)
            _ai_helper_check_claude_code || return 1
            _ai_helper_exec claude "$@"
            ;;
        g|gemini)
            _ai_helper_check_gemini || return 1
            _ai_helper_exec gemini "$@"
            ;;
        d|codex)
            _ai_helper_check_codex || return 1
            _ai_helper_exec codex "$@"
            ;;
        help)
            _ai_helper_usage
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
            'c:Run Claude Code'
            'claude:Run Claude Code'
            'g:Run Gemini CLI'
            'gemini:Run Gemini CLI'
            'd:Run Codex CLI'
            'codex:Run Codex CLI'
            'help:Show this help message'
        )
        _describe -t commands "AI Commands" commands
        return 0
    fi

    return 1
}

compdef _ai_helper_completions $_ai_cmd
