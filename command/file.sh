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
                error "Wrong parameter $1."
                file_help
                exit 1
            ;;
        esac

        shift
    done

    if test -z "${command}"; then
        error "Command not specified"
        file_help
        exit 1
    fi
    if test -z "${filepath}"; then
        error "File not specified"
        file_help
        exit 1
    fi
    if test -z "${directory}"; then
        error "Directory not specified"
        file_help
        exit 1
    fi

    # shellcheck disable=SC2154
    for index in ${vm_list}; do
        info "Running on seat-${name}-${index}"

        ip=$(jq --raw-output '.ip' "${script_base_dir}/set/${name}/seat-${name}-${index}.json")

        case "${command}" in
            put)
                scp -i "${script_base_dir}/set/${name}/ssh" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "${filepath}" "root@${ip}:${directory}"
            ;;
            get)
                scp -i "${script_base_dir}/set/${name}/ssh" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "root@${ip}:${filepath}" "${directory}"
            ;;
        esac
    done

    exit 0
}

dns_help() {
    cat <<EOF
seatctl <global options> file <command options>

Transfer files with VMs.

Command options:
  --command      Sub-command to execute (required)
  --file         Source file (required)
  --directory    Targert directory (required)
  --help         Show help

Sub-commands:
  put    Copy file to VMs
  get    Copy file from VMs
EOF
}

file_main "$@"