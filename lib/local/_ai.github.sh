#!/usr/bin/zsh -f
# This is an example and usable custom MCP server provider for lib/ai.sh
#
# All these 4 functions can receive user arguments. Running `ai use github arg1`
# will call function with "arg1" as the first argument.

loadlib node
loadlib _lib

# Show description of this MCP server, should be short as it is used in usage
# message and commandline completion.
function ai_mcp_desc() {
    echo "Manage GitHub repo with AI"
}

# Check and prepare the environment for this MCP server.
# You might want to use helpers in lib/_lib.sh to check or prepare the environment.
#
# An comprehensive example, which check and install a tool (with user confirmation)
# could be:
#
#  _has_prog prog || {
#      echo "This MCP server requires 'prog' to be installed."
#      _confirm "Do you want to install it now?" || return 1
#
#      some_command_to --install "the prog"
#  }
#  [[ -z "$REQUIRED_VAR" ]] || {
#      echo "This MCP server requires 'REQUIRED_VAR' to be set."
#      echo "You could set it in a file and load with 'dotenv' helper automatically."
#      return 1
#  }
function ai_mcp_prepare() {
    curl -so /dev/null https://api.githubcopilot.com/mcp/ || {
        echo "Failed to connect to GitHub!?"
        return 1
    }
    [[ -z "$GITHUB_PERSONAL_ACCESS_TOKEN" ]] && {
        echo "You must set GitHub PAT in GITHUB_PERSONAL_ACCESS_TOKEN variable."
        echo "You can set it in a file and load with 'dotenv' helper automatically."
        return 1
    }
}

# Generate the MCP server configuration for Claude Code.
#
# You may use tools like `jq` to generate the configuration. Following example
# passes node version to the MCP server in "--node-use" argument.
#
#  echo '{"command":"my-prog","args":["--node-use",'
#  node -v | jq . -RcM
#  echo ']}'
function ai_mcp_conf_claude() {
    echo '{"type":"http","url":"https://api.githubcopilot.com/mcp/","headers":{"Authorization":"Bearer ${GITHUB_PERSONAL_ACCESS_TOKEN}","X-MCP-Toolsets":'
    {if [[ -z "$1" ]]
    then
        echo 'issues,pull_requests,repos,users'
    else
        echo "$1"
    fi} | jq . -RcM
    echo '}}'
}

# Like the one above, but for Gemini CLI.
#
# It's here becuase gemini-cli uses different format for Streamable HTTP mode. In
# most cases you can just invoke "ai_mcp_conf_claude" like this one.
function ai_mcp_conf_gemini() {
    echo '{"httpUrl":"https://api.githubcopilot.com/mcp/","headers":{"Authorization":"Bearer ${GITHUB_PERSONAL_ACCESS_TOKEN}","X-MCP-Toolsets":'
    {if [[ -z "$1" ]]
    then
        echo 'issues,pull_requests,repos,users'
    else
        echo "$1"
    fi} | jq . -RcM
    echo '}}'
}
