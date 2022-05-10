#!/bin/bash

sudo_main() {
    while test "$#" -gt 0; do
        local parameter=$1
        shift

        case "${parameter}" in
            --help)
                sudo_help
                exit 0
            ;;
            *)
                error "Wrong parameter ${parameter}."
                sudo_help
                exit 1
            ;;
        esac

        shift
    done

    # shellcheck disable=SC2154
    for index in ${vm_list}; do
        # shellcheck disable=SC2154
        info "Running on seat-${name}-${index}"

        # shellcheck disable=SC2154
        ip=$(jq --raw-output '.ip' "${script_base_dir}/set/${name}/seat-${name}-${index}.json")

        echo "seat ALL=(ALL) NOPASSWD:ALL" | ssh -i "${script_base_dir}/set/${name}/ssh" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "root@${ip}" "cat >/etc/sudoers.d/seat"
    done

    exit 0
}

sudo_help() {
    cat <<EOF
seatctl <global options> sudo

Sets sudo without password.

Command options:
  --help      Show help
EOF
}

sudo_main "$@"