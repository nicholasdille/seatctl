#!/bin/bash

function run_ssh() {
    # shellcheck disable=SC2154
    if ! test -f "${script_base_dir}/set/${name}/ssh"; then
        error "Missing SSH key"
        exit 1
    fi

    run_on_set

    exit 0
}

run_ssh "$@"