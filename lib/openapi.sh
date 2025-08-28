#!/usr/bin/zsh -f
# shortcuts to view/create documents from openapi specs, must set OPENAPI_SPEC_FILE before using these helpers

if [[ -z "$OPENAPI_SPEC_FILE" ]]
then
    echo "Please set OPENAPI_SPEC_FILE to the path of your openapi spec file (openapi.json/swagger.json)"
    return 1
fi

# run swagger-ui at 0.0.0.0:11111
function openapi_local_srv() {
    if [[ -z "$OPENAPI_SPEC_FILE" ]]
    then
        echo "Please set OPENAPI_SPEC_FILE to the path of your openapi spec file (openapi.json/swagger.json)"
        return 1
    fi
    local full_path="$(realpath $OPENAPI_SPEC_FILE)"
    local fn="$(basename "$full_path")"
    docker run -d --rm -p 11111:8080 -e "SWAGGER_JSON=/$fn" -v "$full_path:/$fn:ro" docker.swagger.io/swaggerapi/swagger-ui
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
