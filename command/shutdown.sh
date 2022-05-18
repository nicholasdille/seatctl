#!/bin/bash

function shutdown_main() {
    assert_functions "Missing VM provider" shutdown_virtual_machine

    while test "$#" -gt 0; do
        local parameter=$1
        shift

        case "${parameter}" in
            --help)
                shutdown_help
                exit 0
            ;;
            *)
                error "Wrong parameter ${parameter}."
                shutdown_help
                exit 1
            ;;
        esac
    done

    # shellcheck disable=SC2154
    for index in ${vm_list}; do
        info "Shutting down virtual machine..."
        shutdown_virtual_machine "${name}" "${index}"
    done

    exit 0
}

shutdown_help() {
    cat <<EOF
seatctl <global options> shutdown

Shuts down a virtual machine. Requires virtual machine provider.

Command options:
  --help    Show help
EOF
}

shutdown_main "$@"