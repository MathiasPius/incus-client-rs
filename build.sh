#!/usr/bin/env bash
set -ueo pipefail

TEMP_DIR="/tmp/incus-client-sdk-rust"
mkdir -p $TEMP_DIR

# Run the extract_openapi.py script in docker.
# The first argument is the git tag use when fetching
# the incus api specification from GitHub. e.g: v7.3.0
extract() {
    INCUS_REFERENCE="$1"
    shift

    mkdir -p "${TEMP_DIR}/uv"
    mkdir -p "${TEMP_DIR}/${INCUS_REFERENCE}"
    curl -sLo "${TEMP_DIR}/${INCUS_REFERENCE}/rest-api.yaml" "https://raw.githubusercontent.com/lxc/incus/refs/tags/${INCUS_REFERENCE}/doc/rest-api.yaml"    

    docker run -it --rm                         \
        -u "$(id -u):$(id -g)"                  \
        -v $(pwd):/data                         \
        -v ${TEMP_DIR}/uv:/.cache/uv            \
        -v ${TEMP_DIR}/${INCUS_REFERENCE}:/tmp  \
        astral/uv:python3.13-alpine3.23         \
        uv run --script /data/extract_openapi.py /tmp/rest-api.yaml $@
}

build() {
    # `--skip-validate-spec` is required because the upstream Incus spec has minor
    # OpenAPI conformance issues (extra `example` fields, missing parameter declarations)
    # that do not affect the generated code.
    docker run -it --rm                         \
        -u "$(id -u):$(id -g)"                  \
        -v $(pwd):/data                         \
        openapitools/openapi-generator-cli:v7.24.0              \
        generate                                                \
            -i /data/my-subset.yaml                             \
            -g rust                                             \
            -o /data/incus-client/                              \
            --library reqwest                                   \
            --package-name incus-client                         \
            --skip-validate-spec                                \
            --additional-properties=supportAsync=true

    mv incus-client/README.md incus-client/README_API.md
    cp README.md incus-client/README.md
    rm -r incus-client/.openapi-generator
}

CMD="$1"; shift
case "$CMD" in
    "list")
        extract "$1" --list ;;
    "include")
        extract $@ -o /data/my-subset.yaml ;;
    "build")
        build ;;
    *)
        echo "Unknown command" ;;
esac

