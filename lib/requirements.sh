#!/bin/bash

function ensure_command() {
    local file="$1"
    local name="$2"

    local definition="$(yq --output-format json eval "${file}" | jq --raw-output --arg name "${name}" '.requirements[] | select(.name == $name)')"
    #>&2 echo "definition=<${definition}>"

    local present=false
    local match=false

    if type "${script_base_dir}/bin/${package}" >/dev/null 2>&1; then
        echo -n " present..."
        present=true
    fi

    if $present; then
        local version_command="$(echo "${definition}" | jq --raw-output '.command.version')"
        local required_version="$(echo "${definition}" | jq --raw-output '.version')"
        local installed_version="$(eval "${script_base_dir}/bin/${version_command}")"
        if echo "${installed_version}" | grep --quiet ${required_version}; then
            echo -n " version matches..."
            match=true
        fi
    fi

    if ! ${present} || ! ${match}; then
        local install_command="$(echo "${definition}" | jq --raw-output '.command.install')"

        >&2 echo -n " installing..."
        (cd "${script_base_dir}/bin" && eval "${install_command}")
    fi

    >&2 echo " done."
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

    if ! which yq 2>&1 >/dev/null && yq --version | cut -d' ' -f4 | grep -q '^3\.' -; then
        error "yq is not present or version is not >= 4"
        exit 1
    fi

    yq --output-format json eval "${file}" | \
        jq --raw-output '.requirements[].name' | \
        while read -r package; do
            >&2 echo -n "Processing ${package}..."
            ensure_command "${file}" "${package}"
        done
}