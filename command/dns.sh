#!/bin/bash

function dns_main() {
    assert_functions "Missing DNS provider" exists_dns_record create_dns_record remove_dns_record get_dns_record

    local command
    local zone
    local force=false

    while test "$#" -gt 0; do
        case "$1" in
            --command)
                shift
                command=$1
            ;;
            --zone)
                shift
                zone=$1
            ;;
            --force)
                force=true
            ;;
            --help)
                dns_help
                exit 0
            ;;
            *)
                error "Wrong parameters"
                dns_help
                exit 1
            ;;
        esac

        shift
    done

    echo "command=${command} zone=${zone}"

    if test -z "${command}"; then
        error "Command not specified"
        dns_help
        exit 1
    fi
    if test -z "${zone}"; then
        error "DNS zone not specified"
        dns_help
        exit 1
    fi

    # shellcheck disable=SC2154
    for index in ${vm_list}; do
        info "Running on seat-${name}-${index}"

        local ip
        ip=$(jq --raw-output '.ip' "${script_base_dir}/set/${name}/seat-${name}-${index}.json")

        case "${command}" in
            add)
                if ! ${force} && exists_dns_record "${zone}" "seat${index}" A; then
                    info "DNS record for seat${index}.${zone} already exists"
                else
                    info "Creating DNS record for seat${index}.${zone}..."
                    create_dns_record "${zone}" "seat${index}" A "${ip}"
                fi
                if exists_dns_record "${zone}" "*.seat${index}" CNAME; then
                    info "DNS record for *.seat${index}.${zone} already exists"
                else
                    info "Creating DNS record for *.seat${index}.${zone}..."
                    create_dns_record "${zone}" "*.seat${index}" CNAME "seat${index}.${zone}"
                fi
            ;;
            remove)
                if exists_dns_record "${zone}" "seat${index}" A; then
                    info "Removing DNS record for seat${index}.${zone}..."
                    remove_dns_record "${zone}" "seat${index}"
                else
                    info "DNS record for seat${index}.${zone} does not exist"
                fi
                if exists_dns_record "${zone}" "*.seat${index}" CNAME; then
                    info "Removing DNS record for *.seat${index}.${zone}..."
                    remove_dns_record "${zone}" "*.seat${index}"
                else
                    info "DNS record for *.seat${index}.${zone} does not exist"
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

dns_help() {
    cat <<EOF
seatctl <global options> dns <command options>

Adds DNS records. Required DNS provider.

Command options:
  --zone       DNS zone for records (required)
  --command    Sub-command to execute (required)
  --help       Show help

Sub-commands:
  add       Add DNS records for VM
  remove    Remove DNS records for VM
  show      Show DNS records for VM
EOF
}

dns_main "$@"