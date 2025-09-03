#!/usr/bin/zsh -f
# shortcuts to view/create documents from openapi specs, must set OPENAPI_SPEC_FILE before using these helpers

if [[ -z "$OPENAPI_SPEC_FILE" ]]
then
    echo "Please set OPENAPI_SPEC_FILE to the path of your openapi spec file (openapi.json/swagger.json)"
    return 1
fi

function _openapi_helper_docker_name() {
    echo "$(basename "$_RMI_WORK_HERE" | sed 's/[ ]/-/')-swagger-ui"
}

function _openapi_helper_docker_stop() {
    local name="$(_openapi_helper_docker_name)"
    docker rm -f "$name"
}

# run swagger-ui at 0.0.0.0:11111
function _openapi_helper_docker_start() {
    if [[ -z "$OPENAPI_SPEC_FILE" ]]
    then
        echo "Please set OPENAPI_SPEC_FILE to the path of your openapi spec file (openapi.json/swagger.json)"
        return 1
    fi
    (
        backroot
        local name="$(_openapi_helper_docker_name)"
        if echo "$OPENAPI_SPEC_FILE" | grep -qE '^(http|https)://'
        then
            local args=(-e "URL=${OPENAPI_SPEC_FILE}")
            local k
            set|grep -E '^SWAGGER_UI_' | cut -d '=' -f 1 | while read k
            do
                local name="${k#SWAGGER_UI_}"
                args+=(-e "${name}=${(P)k}")
            done
            docker run -d --rm --name "$name" -p 11111:8080 "${args[@]}" docker.swagger.io/swaggerapi/swagger-ui || return $?
        else
            local full_path="$(realpath $OPENAPI_SPEC_FILE)"
            local fn="$(basename "$full_path")"
            docker run -d --rm --name "$name" -p 11111:8080 -e "SWAGGER_JSON=/$fn" -v "${full_path}:/${fn}:ro" docker.swagger.io/swaggerapi/swagger-ui || return $?
        fi
        
        echo "you can visit http://localhost:11111 to view the docs"
        echo "to stop the server, run: 'swagger stop' or 'docker stop $name'"
    )
}

function swagger() {
    case "$1" in
        start)
            _openapi_helper_docker_start
            ;;
        stop)
            _openapi_helper_docker_stop
            ;;
        status)
            docker ps | grep "$(_openapi_helper_docker_name)"
            ;;
        *)
            docker "$@" "$(_openapi_helper_docker_name)"
            ;;
    esac
}

# generate html documentation using redocly
function openapi_html() {
    (
        loadlib node
        local fn="$(basename "$OPENAPI_SPEC_FILE")"
        local dest="${fn%.*}.html"
        NODE_PX --package @redocly/cli redocly build-docs "$OPENAPI_SPEC_FILE" -o "$dest"
    )
}
