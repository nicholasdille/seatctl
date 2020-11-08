#!/bin/bash

(
    echo "Set Index Provisioned Available"

    # shellcheck disable=SC2154
    for index in ${vm_list}; do
        echo -n "${name} ${index}"
        if exists_virtual_machine "${name}" "${index}"; then
            echo -n " yes"
        else
            echo -n " no"
        fi
        echo -n " TODO"
        echo
    done
) | column -t

exit 0