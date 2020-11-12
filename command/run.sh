#!/bin/bash

function run_main() {
    while test "$#" -gt 0; do
        local parameter=$1
        shift

        case "${parameter}" in
            --)
                break
            ;;
            *)
                error "Unknown parameter <${parameter}> for command"
            ;;
        esac

        shift
    done
    command=("$@")

    if test "${#command[@]}" -eq 0; then
        error "Command must be specified"
        exit 1
    fi

    # shellcheck disable=SC2154
    if ! test -f "${script_base_dir}/set/${name}/ssh"; then
        error "Missing SSH key"
        exit 1
    fi

    # shellcheck disable=SC2154
    for index in ${vm_list}; do
        info "Running on seat-${name}-${index}"
        ip=$(jq --raw-output '.ip' set/${name}/seat-${name}-${index}.json)
        ssh -i "${script_base_dir}/set/${name}/ssh" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "root@${ip}" "${command[@]}"
    done

    exit 0
}

run_main "$@"