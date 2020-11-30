#!/bin/bash

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

    yq --tojson read "${file}" | \
        jq --raw-output '.requirements[].name' | \
        while read -r package; do
            >&2 echo -n "Processing ${package}..."
            if ! type "${script_base_dir}/bin/hcloud" >/dev/null 2>&1; then
                >&2 echo -n " installing..."
                # shellcheck disable=SC2154
                curl --silent https://pkg.dille.io/pkgctl.sh | \
                    TARGET_BASE="${script_base_dir}" bash -s install "${package}"
                rm -rf "${script_base_dir:?}/etc"
                >&2 echo " done."

            else
                >&2 echo " present."
            fi
        done
}