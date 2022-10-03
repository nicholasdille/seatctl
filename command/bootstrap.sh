#!/bin/bash

function bootstrap_main() {

    while test "$#" -gt 0; do
        local parameter=$1
        shift

        case "${parameter}" in
            --help)
                bootstrap_help
                exit 0
            ;;
            *)
                error "Wrong parameter ${parameter}."
                bootstrap_help
                exit 1
            ;;
        esac
    done

    # shellcheck disable=SC2154
    if ! test -f "${script_base_dir}/set/${name}/ssh"; then
        # shellcheck disable=SC2154
        mkdir -p "${script_base_dir}/set/${name}"
        # shellcheck disable=SC2154
        if ! test -f "${script_base_dir}/set/${name}/ssh"; then
            # shellcheck disable=SC2154
            ssh-keygen -f "${script_base_dir}/set/${name}/ssh" -t ed25519 -N ''
        fi
    fi

    create_ssh_key "${name}" "${script_base_dir}/set/${name}/ssh.pub"

    exit 0
}

bootstrap_help() {
    cat <<EOF
seatctl <global options> wait

Wait for a virtual machine to be available.

Command options:
  --help    Show help
EOF
}

bootstrap_main "$@"