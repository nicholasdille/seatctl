#!/bin/bash

function local_main() {
    local command

    while test "$#" -gt 0; do
        case "$1" in
            --command)
                shift
                command=$1
            ;;
            --help)
                local_help
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

    echo "command=${command}"

    if test -z "${command}"; then
        error "Command not specified"
        dns_help
        exit 1
    fi

    for index in ${vm_list}; do
        info "Running on seat-${name}-${index}"

        local ip
        ip=$(jq --raw-output '.ip' "${script_base_dir}/set/${name}/seat-${name}-${index}.json")

        case "${command}" in
            ssh)
                cat >"${HOME}/.ssh/config.d/${name}-seat${index}" <<EOF
Host seat${index}
    HostName ${ip}
    User root
    IdentityFile ${script_base_dir}/set/${name}/ssh
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF
            ;;
        esac

    done


    exit 0
}

local_help() {
    cat <<EOF
seatctl <global options> var <command options>

Change local.

Command options:
  --command    Sub-command to execute (required)
  --help       Show help

Sub-commands:
  ssh       Add local ssh config for VM
EOF
}

local_main "$@"