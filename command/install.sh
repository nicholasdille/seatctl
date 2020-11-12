#!/bin/bash

function run_install() {
    local packages=("$@")

    if test "${#packages[@]}" -eq 0; then
        error "Package(s) must be specified"
        exit 1
    fi

    # shellcheck disable=SC2154
    if ! test -f "${script_base_dir}/set/${name}/ssh"; then
        error "Missing SSH key"
        exit 1
    fi

    run_on_set "curl --silent https://pkg.dille.io/pkg.sh | bash -s bootstrap --prefix /usr/local"
    for pkg in ${packages[@]}; do
        run_on_set pkg install "${pkg}"
    done

    exit 0
}

run_install "$@"