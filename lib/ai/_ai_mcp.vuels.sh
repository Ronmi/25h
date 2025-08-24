#!/usr/bin/zsh -f

function ai_mcp_desc() {
    echo "Vue language server"
}

function ai_mcp_prepare() {
    _has_prog vue-language-server || {
        echo "Error: vue-language-server is not installed."
        _confirm "Do you want to install it now?" || return 1
        NODEPM install -g @vue/language-server || return 1
    } || return 1

    _has_prog mcp-language-server || {
        echo "Error: mcp-language-server is not installed."
        _confirm "Do you want to install it now?" || return 1
        go install github.com/isaacphi/mcp-language-server@latest
        return $?
    } || return 1
}

function ai_mcp_conf_claude() {
    echo '{"command": "mcp-language-server", "args": '

    _args_to_json \
        "--workspace" \
        "$_RMI_WORK_HERE" \
        "--lsp" \
        "vue-language-server" \
        "--" \
        "--stdio"

    echo '}'
}

function ai_mcp_conf_gemini() {
    ai_mcp_conf_claude
}
