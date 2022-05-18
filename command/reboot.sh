#!/bin/bash

function reboot_main() {
    assert_functions "Missing VM provider" reboot_virtual_machine

    while test "$#" -gt 0; do
        local parameter=$1
        shift

        case "${parameter}" in
            --help)
                reboot_help
                exit 0
            ;;
            *)
                error "Wrong parameter ${parameter}."
                reboot_help
                exit 1
            ;;
        esac
    done

    # shellcheck disable=SC2154
    for index in ${vm_list}; do
        info "Rebooting virtual machine..."
        reboot_virtual_machine "${name}" "${index}"
    done

    exit 0
}

reboot_help() {
    cat <<EOF
seatctl <global options> reboot

Reboot a virtual machine. Requires virtual machine provider.

Command options:
  --help    Show help
EOF
}

reboot_main "$@"