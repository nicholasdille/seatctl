#!/bin/bash

function ssh_main() {
    local type=root

    while test "$#" -gt 0; do
        local parameter=$1
        shift

        case "${parameter}" in
            --type)
                type=$1
            ;;
            --help)
                ssh_help
                exit 0
            ;;
            *)
                error "Wrong parameter ${parameter}."
                ssh_help
                exit 1
            ;;
        esac

        shift
    done

    if test "${type}" == "user"; then
        for index in ${vm_list}; do
            ip=$(jq --raw-output '.ip' set/${name}/seat-${name}-${index}.json)
            ssh -i "${script_base_dir}/set/${name}/ssh" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "seat${index}@${ip}"
        done

    else
        # shellcheck disable=SC2154
        if ! test -f "${script_base_dir}/set/${name}/ssh"; then
            error "Missing SSH key"
            exit 1
        fi

        run_on_set
    fi

    exit 0
}

ssh_help() {
    cat <<EOF
seatctl <global options> ssh <options>

Enters a remote shell using SSH.

Command options:
  --type      XXX (optional, defaults to root)
  --help      XXX
EOF
}

ssh_main "$@"