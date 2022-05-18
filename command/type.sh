#!/bin/bash

function type_main() {
    assert_functions "Missing VM provider" change_type_virtual_machine

    local type=cx31

    while test "$#" -gt 0; do
        case "$1" in
            --type)
                shift
                type=$1
            ;;
            --help)
                type_help
                exit 0
            ;;
            *)
                error "Wrong parameter ${parameter}."
                type_help
                exit 1
            ;;
        esac

        shift
    done

    # shellcheck disable=SC2154
    for index in ${vm_list}; do
        info "Changing type of virtual machine..."
        change_type_virtual_machine "${name}" "${index}" "${type}"
    done

    exit 0
}

type_help() {
    cat <<EOF
seatctl <global options> type <new-type>

Change the type of a virtual machine. Requires virtual machine provider.

Command options:
  --type    New type
  --help    Show help
EOF
}

type_main "$@"