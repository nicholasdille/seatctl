#!/bin/bash

function remove_main() {
    if test "$#" -gt 0; then
        error "Command add does not accept any parameters"
    fi

    # shellcheck disable=SC2154
    for index in ${vm_list}; do
        echo "INFO: Removing virtual machine..."
        remove_virtual_machine "${name}" "${index}"
        echo "VERBOSE: Removing seat info..."
        rm -f "${script_base_dir}/set/${name}/seat-${name}-${index}.json"
    done

    exit 0
}

remove_main "$@"