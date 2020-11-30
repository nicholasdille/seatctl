#!/bin/bash

function run_install() {
    local packages=()

    while test "$#" -gt 0; do
        local parameter=$1
        shift

        case "${parameter}" in
            --help)
                install_help
                exit 0
            ;;
            *)
                packages+=("${parameter}")
            ;;
        esac
    done

    if test "${#packages[@]}" -eq 0; then
        error "Package(s) must be specified"
        install_help
        exit 1
    fi

    # shellcheck disable=SC2154
    if ! test -f "${script_base_dir}/set/${name}/ssh"; then
        error "Missing SSH key"
        install_help
        exit 1
    fi

    run_on_set "curl --silent https://pkg.dille.io/pkgctl.sh | bash -s bootstrap --prefix /usr/local"
    for pkg in ${packages[@]}; do
        run_on_set pkg install "${pkg}"
    done

    exit 0
}

install_help() {
    cat <<EOF
seatctl <global options> install <package>[ <package>...]

Installs packages using https://github.com/nicholasdille/packages.

Command options:
  --help    XXX
EOF
}

run_install "$@"