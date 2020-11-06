#!/bin/bash

function remove_main() {
    if test "$#" -gt 0; then
        error "Command add does not accept any parameters"
    fi

    # shellcheck disable=SC2154
    for vm_index in ${vm_list}; do
        remove_virtual_machine "${name}" "${vm_index}"
    done

    exit 0
}

remove_main "$@"