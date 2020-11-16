#!/bin/bash

function file_main() {
    local command
    local filepath
    local directory

    while test "$#" -gt 0; do
        local parameter=$1
        shift

        case "${parameter}" in
            --command)
                command=$1
            ;;
            --file)
                filepath=$1
            ;;
            --directory)
                directory=$1
            ;;
            --help)
                file_help
                exit 0
            ;;
            *)
                echo "ERROR: Wrong parameter $1."
                file_help
                exit 1
            ;;
        esac

        shift
    done

    if test -z "${command}"; then
        echo "ERROR: Command not specified"
        file_help
        exit 1
    fi
    if test -z "${filepath}"; then
        echo "ERROR: File not specified"
        file_help
        exit 1
    fi
    if test -z "${directory}"; then
        echo "ERROR: Directory not specified"
        file_help
        exit 1
    fi

    # shellcheck disable=SC2154
    for index in ${vm_list}; do
        info "Running on seat-${name}-${index}"

        ip=$(jq --raw-output '.ip' set/${name}/seat-${name}-${index}.json)

        case "${command}" in
            put)
                scp -i "${script_base_dir}/set/${name}/ssh" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${filepath}" "root@${ip}:${directory}"
            ;;
            get)
                scp -i "${script_base_dir}/set/${name}/ssh" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "root@${ip}:${filepath}" "${directory}"
            ;;
        esac
    done

    exit 0
}

dns_help() {
    cat <<EOF
seatctl <global options> file <command options>

Adds DNS records.

Command options:
  --command      XXX (required)
  --file         XXX (required)
  --directory    XXX (required)
  --help         XXX

Sub-commands:
  put    XXX
  get    XXX
EOF
}

file_main "$@"