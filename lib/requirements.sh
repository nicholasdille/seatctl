#!/bin/bash

function ensure_command() {
    local file="$1"
    local name="$2"

    local definition="$(
        cat requirements.json | \
            jq --raw-output --arg name "${name}" '.requirements[] | select(.name == $name)'
    )"

    local present=false
    local match=false

    if type "${script_base_dir}/bin/${package}" >/dev/null 2>&1; then
        verbose "+- Requirement present"
        present=true
    fi

    if $present; then
        local version_command="$(echo "${definition}" | jq --raw-output '.command.version')"
        local required_version="$(echo "${definition}" | jq --raw-output '.version')"
        local installed_version="$(eval "${script_base_dir}/bin/${version_command}")"
        if echo "${installed_version}" | grep --quiet ${required_version}; then
            verbose "+- Version matches"
            match=true
        fi
    fi

    if ! ${present} || ! ${match}; then
        local install_command="$(echo "${definition}" | jq --raw-output '.command.install')"

        verbose "+- Installing"
        (cd "${script_base_dir}/bin" && eval "${install_command}")
    fi
}

function process_requirements() {
    local file=$1

    if test -z "${file}"; then
        error "The path and filename for requirements.yaml must be supplied"
        exit 1
    fi
    if ! test -f "${file}"; then
        error "The path and filename for requirements.yaml must exist"
        exit 1
    fi

    if ! test -f "${script_base_dir}/bin/yq"; then
        curl https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
            --silent \
            --location \
            --output "${script_base_dir}/bin/yq"
        chmod +x "${script_base_dir}/bin/yq"
    fi

    "${script_base_dir}/bin/yq" --output-format json eval "${file}" >requirements.json
    cat requirements.json | \
        jq --raw-output '.requirements[].name' | \
        while read -r package; do
            verbose "Processing ${package}..."
            ensure_command "${file}" "${package}"
        done
}