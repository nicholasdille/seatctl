#!/bin/bash

function dns_main() {
    local command
    local zone

    while test "$#" -gt 0; do
        local parameter=$1
        shift

        case "${parameter}" in
            --command)
                command=$1
            ;;
            --zone)
                zone=$1
            ;;
            *)
                echo "ERROR: Wrong parameters"
                exit 1
            ;;
        esac

        shift
    done

    if test -z "${command}"; then
        echo "ERROR: Command not specified"
        exit 1
    fi
    if test -z "${zone}"; then
        echo "ERROR: DNS zone not specified"
        exit 1
    fi

    # shellcheck disable=SC2154
    for index in ${vm_list}; do
        info "Running on seat-${name}-${index}"

        local ip
        ip=$(jq --raw-output '.ip' set/${name}/seat-${name}-${index}.json)

        case "${command}" in
            add)
                if exists_dns_record "${zone}" "seat${index}" A; then
                    echo "INFO: DNS record for seat${index}.${zone} already exists"
                else
                    create_dns_record "${zone}" "seat${index}" A "${ip}"
                fi
            ;;
            remove)
                if exists_dns_record "${zone}" "seat${index}" A; then
                    remove_dns_record "${zone}" "seat${index}" A
                else
                    echo "INFO: DNS record for seat${index}.${zone} does not exist"
                fi
            ;;
        esac
    done

    exit 0
}

dns_main "$@"