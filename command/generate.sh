#!/bin/bash

function generate_main() {
    local zone
    local length=32

    while test "$#" -gt 0; do
        local parameter=$1
        shift

        case "${parameter}" in
            --zone)
                zone=$1
            ;;
            --length)
                length=$1
            ;;
            *)
                echo "ERROR: Wrong parameters"
                exit 1
            ;;
        esac

        shift
    done
    
    if test -z "${zone}"; then
        echo "ERROR: DNS zone not specified"
        exit 1
    fi

    # shellcheck disable=SC2154
    for index in ${vm_list}; do
        local password
        password=$(openssl rand -hex 32)

        echo "seat${index};seat${index}.${zone};${password}"
    done

    exit 0
}

generate_main "$@"