#!/bin/bash

list_main() {
    while test "$#" -gt 0; do
        local parameter=$1
        shift

        case "${parameter}" in
            --help)
                list_help
                exit 0
            ;;
            *)
                echo "ERROR: Wrong parameter ${parameter}."
                list_help
                exit 1
            ;;
        esac

        shift
    done

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
}

list_help() {
    cat <<EOF
seatctl <global options> list

List virtual machine.

Command options:
  --help      XXX
EOF
}

exit 0