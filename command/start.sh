#!/bin/bash

function start_main() {
    assert_functions "Missing VM provider" start_virtual_machine

    while test "$#" -gt 0; do
        local parameter=$1
        shift

        case "${parameter}" in
            --help)
                start_help
                exit 0
            ;;
            *)
                error "Wrong parameter ${parameter}."
                start_help
                exit 1
            ;;
        esac
    done

    # shellcheck disable=SC2154
    for index in ${vm_list}; do
        info "Start virtual machine..."
        start_virtual_machine "${name}" "${index}"
    done

    exit 0
}

start_help() {
    cat <<EOF
seatctl <global options> start

Starts a virtual machine. Requires virtual machine provider.

Command options:
  --help    Show help
EOF
}

start_main "$@"