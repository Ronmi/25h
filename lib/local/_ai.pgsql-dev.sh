#!/usr/bin/zsh -f
#
# This is an MCP server for managing PostgreSQL database with AI.
# It provides r/w access to the database, allowing you to create, read, update,
# and delete records in the database using AI tools.

loadlib node
loadlib _lib

# required environment variables:
# POSTGRES_HOST
# POSTGRES_PORT
# POSTGRES_USER
# POSTGRES_PASSWORD
# POSTGRES_DB

# Show description of this MCP server, should be short as it is used in usage
# message and commandline completion.
function ai_mcp_desc() {
    echo "Manage PostgreSQL database, work best with 'dev-pgsql' helper"
}

function ai_mcp_prepare() {
    if [[ -z "$POSTGRES_HOST" || -z "$POSTGRES_PORT" || -z "$POSTGRES_USER" || -z "$POSTGRES_PASSWORD" || -z "$POSTGRES_DB" ]]
    then
        echo "Error: Required environment variables are not set." >&2
        return 1
    fi
    _has_prog docker || {
        echo "Error: 'docker' is not installed or not in PATH." >&2
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
    echo '{"command":"docker","args":["run","-i","--rm","-e","DATABASE_URI=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}","crystaldba/postgres-mcp","--access-mode=unrestricted"]}'
}

# Like the one above, but for Gemini CLI.
#
# It's here becuase gemini-cli uses different format for Streamable HTTP mode. In
# most cases you can just invoke "ai_mcp_conf_claude" like this one.
function ai_mcp_conf_gemini() {
    ai_mcp_conf_claude
}
