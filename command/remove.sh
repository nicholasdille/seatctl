#!/bin/bash

function remove_main() {
    while test "$#" -gt 0; do
        local parameter=$1
        shift

        case "${parameter}" in
            --help)
                remove_help
                exit 0
            ;;
            *)
                error "Wrong parameter ${parameter}."
                remove_help
                exit 1
            ;;
        esac
    done

    # shellcheck disable=SC2154
    for index in ${vm_list}; do
        info "Removing virtual machine..."
        remove_virtual_machine "${name}" "${index}"
        verbose "Removing seat info..."
        rm -f "${script_base_dir}/set/${name}/seat-${name}-${index}.json"
    done

    exit 0
}

remove_help() {
    cat <<EOF
seatctl <global options> remove

Removes a virtual machine. Requires virtual machine provider.

Command options:
  --help    XXX
EOF
}

remove_main "$@"