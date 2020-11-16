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
            --help)
                generate_help
                exit 0
            ;;
            *)
                echo "ERROR: Wrong parameters"
                generate_help
                exit 1
            ;;
        esac

        shift
    done
    
    if test -z "${zone}"; then
        echo "ERROR: DNS zone not specified"
        generate_help
        exit 1
    fi

    echo "hostname;username;password"
    # shellcheck disable=SC2154
    for index in ${vm_list}; do
        local password
        password=$(openssl rand -hex "${length}")

        echo "seat${index}.${zone};seat${index};${password}"
    done

    exit 0
}

generate_help() {
    cat <<EOF
seatctl <global options> generate <command options>
seatctl <global options> generate <command options>

Generates passwords.

Command options:
  --zone      XXX (required)
  --length    XXX (optional, defaults to 32)
  --help      XXX
EOF
}

generate_main "$@"