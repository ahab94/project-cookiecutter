#!/bin/bash

PROJECT_FILE="${PROJECT_FILE:-project.yml}"
VERSION="${VERSION:?missing required input \'VERSION\'}"

get_targets() {
    local data

    data=$(yaml -j read project.yml metadata.build[*] | jq -r '.[] | [ .["target"] ] | join(" ")')
    echo "$data"
}

build() {
    local project
    local import_path
    local ldflags

    project=$(yaml read "${PROJECT_FILE}" metadata.name)
    import_path=$(yaml read "${PROJECT_FILE}" metadata.import)

    ldflags="-X ${import_path}/version.GitCommit=$(git rev-parse --short HEAD)"
    ldflags="${ldflags} -X ${import_path}/version.GitDescribe=$(git describe --tags --always)"

    mapfile -t targets < <(get_targets)
    for pkg in "${targets[@]}"; do
        binary=$(basename "${pkg}")
        gox \
            -ldflags "${ldflags}" \
            -arch="amd64" \
            -arch="386" \
            -os="darwin" \
            -os="linux" \
            -os="windows" \
            -output="build/${project}_${VERSION}_{{ "{{" }}.OS{{ "}}" }}_{{ "{{" }}.Arch{{ "}}" }}/${binary}" "${import_path}/${pkg}"
    done
}

build
