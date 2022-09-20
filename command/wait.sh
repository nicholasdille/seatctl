#!/bin/bash

function wait_main() {

    while test "$#" -gt 0; do
        local parameter=$1
        shift

        case "${parameter}" in
            --help)
                wait_help
                exit 0
            ;;
            *)
                error "Wrong parameter ${parameter}."
                wait_help
                exit 1
            ;;
        esac
    done

    # shellcheck disable=SC2154
    if ! test -f "${script_base_dir}/set/${name}/ssh"; then
        error "Missing SSH key"
        exit 1
    fi

    # shellcheck disable=SC2154
    for index in ${vm_list}; do
        # shellcheck disable=SC2154
        ip=$(jq --raw-output '.ip' "${script_base_dir}/set/${name}/seat-${name}-${index}.json")
        info "Waiting for SSH to be available on VM ${index}..."
        while ! ssh -i "${script_base_dir}/set/${name}/ssh" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "root@${ip}" -- true; do
            sleep 10
        done
    done

    exit 0
}

wait_help() {
    cat <<EOF
seatctl <global options> wait

Wait for a virtual machine to be available.

Command options:
  --help    Show help
EOF
}

wait_main "$@"