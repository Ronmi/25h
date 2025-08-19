#!/usr/bin/zsh -f
# create postgres database service with docker for local development

# customizable variables
DEV_PGSQL_PREFIX="${DEV_PGSQL_PREFIX:-$(basename "$_RMI_WORK_HERE")}"
DEV_PGSQL_INIT_DIR="${DEV_PGSQL_INIT_DIR:-$(pwd)/db_schema}"
POSTGRES_DB="${POSTGRES_DB:-$DEV_PGSQL_PREFIX}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-devpass}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"

# automatically set the PostgreSQL host based on the port
POSTGRES_HOST="localhost"
if [[ "$(echo "${POSTGRES_PORT}:" | cut -d : -f 2)" != "" ]]; then
    POSTGRES_HOST="$(echo "${POSTGRES_PORT}:" | cut -d : -f 1)"
fi
export POSTGRES_HOST POSTGRES_DB POSTGRES_USER POSTGRES_PASSWORD POSTGRES_PORT

_pg_cmd="${_pg_cmd_name:=pg}"
_set_helper "$_pg_cmd" "PosgreSQL server" _run_dev-pgsql_cmd


function _dev-pgsql_usage() {
    cat <<USAGE
Usage: ${_pg_cmd} start|stop|status
Start, stop, or check the status of a PostgreSQL development database container.

Commands:
  start   Start the PostgreSQL development database container.
  stop    Stop and remove the PostgreSQL development database container.
          Note: If you have unsaved changes in the database, they will be lost on
          container stop and removal. Use with caution.
  restart Restart, content will be lost.
  status  Check the status of the PostgreSQL development database container.
USAGE
}

function _dev-pgsql_helper_container_name() {
    echo "${DEV_PGSQL_PREFIX}-dev-pgsql"
}

function _dev-pgsql_helper_start() {
    local container_name="$(_dev-pgsql_helper_container_name)"
    
    # Stop and remove existing container if running
    if docker ps -a --format "table {{.Names}}" | grep -q "^${container_name}$"; then
        echo "Stopping existing container: ${container_name}"
        docker stop "${container_name}" >/dev/null 2>&1
        docker rm "${container_name}" >/dev/null 2>&1
    fi
    
    # Start new PostgreSQL container
    echo "Starting PostgreSQL development database..."
    docker run -d --rm \
        --name "${container_name}" \
        -v "${DEV_PGSQL_INIT_DIR}:/docker-entrypoint-initdb.d:ro" \
        -e "POSTGRES_DB=${POSTGRES_DB}" \
        -e "POSTGRES_USER=${POSTGRES_USER}" \
        -e "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}" \
        -p "${POSTGRES_PORT}:5432" \
        postgres:latest || return $?
    
    echo "Database container started. Connection details:"
    echo -n "  Host:     "
    if [[ "$(echo "${POSTGRES_PORT}:" | cut -d : -f 2)" == "" ]]; then
        echo "localhost"
    else
        echo "$(echo "${POSTGRES_PORT}:" | cut -d : -f 1)"
    fi
    echo "  Port:     ${POSTGRES_PORT}"
    echo "  Database: ${POSTGRES_DB}"
    echo "  Username: ${POSTGRES_USER}"
    echo "  Password: ${POSTGRES_PASSWORD}"
}

function _dev-pgsql_helper_stop() {
    local container_name="$(_dev-pgsql_helper_container_name)"
    
    if docker ps --format "table {{.Names}}" | grep -q "^${container_name}$"; then
        echo "Stopping PostgreSQL development database..."
        docker kill "${container_name}"
        echo "Database container stopped and removed."
    else
        echo "Development database container is not running."
    fi
}

function _dev-pgsql_helper_status() {
    local container_name="$(_dev-pgsql_helper_container_name)"
    
    if docker ps --format "table {{.Names}}" | grep -q "^${container_name}$"; then
        echo "PostgreSQL development database is running."
        docker ps --filter "name=${container_name}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        echo "PostgreSQL development database is not running."
    fi
}

function _dev-pgsql_helper_restart() {
    _dev-pgsql_helper_stop
    _dev-pgsql_helper_start
}

function _run_dev-pgsql_cmd() {
    local action="$1"
    shift
    case "$action" in
        start)
            _dev-pgsql_helper_start
            ;;
        stop)
            _dev-pgsql_helper_stop
            ;;
        restart)
            _dev-pgsql_helper_restart
            ;;
        status)
            _dev-pgsql_helper_status
            ;;
        *)
            _dev-pgsql_usage
            return 1
            ;;
    esac
}

# completion for the command

function _pg_cmd_completions() {
    if (( CURRENT == 2 )); then
        local -a commands
        commands=(
            "start:Start the PostgreSQL development database container"
            "stop:Stop and remove the PostgreSQL development database container"
            "restart:Restart the PostgreSQL development database container (content will be lost)"
            "status:Check the status of the PostgreSQL development database container"
        )
        _describe -t commands "PG Commands" commands
        return 0
    fi
}

compdef _pg_cmd_completions $_pg_cmd
