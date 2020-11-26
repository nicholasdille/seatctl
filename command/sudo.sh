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

    for index in ${vm_list}; do
        info "Running on seat-${name}-${index}"

        ip=$(jq --raw-output '.ip' set/${name}/seat-${name}-${index}.json)

        echo "seat${index} ALL=(ALL) NOPASSWD:ALL" | ssh -i "${script_base_dir}/set/${name}/ssh" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "root@${ip}" "cat >/etc/sudoers.d/seat${index}"
    done
}

sudo_help() {
    cat <<EOF
seatctl <global options> sudo

Sets sudo without password.

Command options:
  --help      XXX
EOF
}

exit 0