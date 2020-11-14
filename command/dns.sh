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

    echo "command=${command} zone=${zone}"

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
                    echo "INFO: Creating DNS record for seat${index}.${zone}..."
                    create_dns_record "${zone}" "seat${index}" A "${ip}"
                fi
                if exists_dns_record "${zone}" "*.seat${index}" CNAME; then
                    echo "INFO: DNS record for *.seat${index}.${zone} already exists"
                else
                    echo "INFO: Creating DNS record for *.seat${index}.${zone}..."
                    create_dns_record "${zone}" "*.seat${index}" CNAME "seat${index}.${zone}"
                fi
            ;;
            remove)
                if exists_dns_record "${zone}" "seat${index}" A; then
                    echo "INFO: Removing DNS record for seat${index}.${zone}..."
                    remove_dns_record "${zone}" "seat${index}"
                else
                    echo "INFO: DNS record for seat${index}.${zone} does not exist"
                fi
                if exists_dns_record "${zone}" "*.seat${index}" CNAME; then
                    echo "INFO: Removing DNS record for *.seat${index}.${zone}..."
                    remove_dns_record "${zone}" "*.seat${index}"
                else
                    echo "INFO: DNS record for *.seat${index}.${zone} does not exist"
                fi
            ;;
            show)
                (
                    echo "Name Type Content"
                    get_dns_record "${zone}" "seat${index}"
                    get_dns_record "${zone}" "*.seat${index}"
                ) | column -t
            ;;
        esac
    done

    exit 0
}

dns_main "$@"