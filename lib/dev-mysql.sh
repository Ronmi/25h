#!/usr/bin/zsh -f
# create mysql database service with docker for local development

# customizable variables
DEV_MYSQL_IMAGE="${DEV_MYSQL_IMAGE:-mysql:latest}"
DEV_MYSQL_PREFIX="${DEV_MYSQL_PREFIX:-$(basename "$_RMI_WORK_HERE")}"
DEV_MYSQL_INIT_DIR="${DEV_MYSQL_INIT_DIR:-$(pwd)/db_schema}"
MYSQL_DATABASE="${MYSQL_DATABASE:-$DEV_MYSQL_PREFIX}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-devpass}"
MYSQL_PORT="${MYSQL_PORT:-3306}"

# automatically set the MySQL host based on the port
MYSQL_HOST="127.0.0.1"
if [[ "$(echo "${MYSQL_PORT}:" | cut -d : -f 2)" != "" ]]; then
    MYSQL_HOST="$(echo "${MYSQL_PORT}:" | cut -d : -f 1)"
fi
export MYSQL_HOST MYSQL_PORT MYSQL_DATABASE MYSQL_ROOT_DATABASE

_mys_cmd="${_mys_cmd_name:=mys}"
_set_helper "$_mys_cmd" "MySQL server" _run_dev-mysql_cmd


function _dev-mysql_usage() {
    cat <<USAGE
Usage: ${_mys_cmd} start|stop|status
Start, stop, or check the status of a MySQL development database container.

Commands:
  info    Display connection information for the MySQL development database.
          This includes host, port, database name, username, and password.
          Note: This information is valid until you change the environment
          variables and restart the container.
  start   Start the MySQL development database container.
  stop    Stop and remove the MySQL development database container.
          Note: If you have unsaved changes in the database, they will be lost on
          container stop and removal. Use with caution.
  restart Restart, content will be lost.
  status  Check the status of the MySQL development database container.
USAGE
}

function _dev-mysql_helper_container_name() {
    echo "${DEV_MYSQL_PREFIX}-dev-mysql"
}

function _dev-mysql_helper_info() {
        echo "Connection details:"
        echo -n "  Host:     "
        if [[ "$(echo "${MYSQL_PORT}:" | cut -d : -f 2)" == "" ]]; then
            echo "localhost"
        else
            echo "$(echo "${MYSQL_PORT}:" | cut -d : -f 1)"
        fi
        echo "  Port:     ${MYSQL_PORT}"
        echo "  Database: ${MYSQL_DATABASE}"
        echo "  Username: root"
        echo "  Password: ${MYSQL_ROOT_PASSWORD}"
        echo
        echo "This information is valid until you change the environment variables"
        echo "and restart the container."
}

function _dev-mysql_helper_start() {
    local container_name="$(_dev-mysql_helper_container_name)"
    
    # Stop and remove existing container if running
    if docker ps -a --format "table {{.Names}}" | grep -q "^${container_name}$"; then
        echo "MySQL development database container already exists."
        _dev-mysql_helper_info
        return 1
    fi
    
    # Start new MySQL container
    echo "Starting MySQL development database..."
    docker run -d --rm \
        --name "${container_name}" \
        -v "${DEV_MYSQL_INIT_DIR}:/docker-entrypoint-initdb.d:ro" \
        -e "MYSQL_DATABASE=${MYSQL_DATABASE}" \
        -e "MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}" \
        -p "${MYSQL_PORT}:3306" \
        "$DEV_MYSQL_IMAGE" || return $?
    
    echo -n "Database container started. "
    _dev-mysql_helper_info
}

function _dev-mysql_helper_stop() {
    local container_name="$(_dev-mysql_helper_container_name)"
    
    if docker ps --format "table {{.Names}}" | grep -q "^${container_name}$"; then
        echo "Stopping MySQL development database..."
        docker rm -f "${container_name}"
        echo "Database container stopped and removed."
    else
        echo "Development database container is not running."
    fi
}

function _dev-mysql_helper_status() {
    local container_name="$(_dev-mysql_helper_container_name)"
    
    if docker ps --format "table {{.Names}}" | grep -q "^${container_name}$"; then
        echo "MySQL development database is running."
        docker ps --filter "name=${container_name}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        echo "MySQL development database is not running."
    fi
}

function _dev-mysql_helper_restart() {
    _dev-mysql_helper_stop
    _dev-mysql_helper_start
}

function _run_dev-mysql_cmd() {
    local action="$1"
    shift
    case "$action" in
        info)
            _dev-mysql_helper_info
            ;;
        start)
            _dev-mysql_helper_start
            ;;
        stop)
            _dev-mysql_helper_stop
            ;;
        restart)
            _dev-mysql_helper_restart
            ;;
        status)
            _dev-mysql_helper_status
            ;;
        *)
            _dev-mysql_usage
            return 1
            ;;
    esac
}

# completion for the command

function _mys_cmd_completions() {
    if (( CURRENT == 2 )); then
        local -a commands
        commands=(
            "info:Display connection information for the MySQL development database"
            "start:Start the MySQL development database container"
            "stop:Stop and remove the MySQL development database container"
            "restart:Restart the MySQL development database container (content will be lost)"
            "status:Check the status of the MySQL development database container"
        )
        _describe -t commands "MYS Commands" commands
        return 0
    fi
}

compdef _mys_cmd_completions $_mys_cmd
