#!/bin/bash

function run_main() {
    while test "$#" -gt 0; do
        local parameter=$1
        shift

        case "${parameter}" in
            --help)
                run_help
                exit 0
            ;;
            --)
                break
            ;;
            *)
                echo "ERROR: Unknown parameter <${parameter}> for command"
                run_help
                exit 1
            ;;
        esac

        shift
    done
    command=("$@")

    if test "${#command[@]}" -eq 0; then
        echo "ERROR: Command must be specified"
        exit 1
    fi

    # shellcheck disable=SC2154
    if ! test -f "${script_base_dir}/set/${name}/ssh"; then
        echo "ERROR: Missing SSH key"
        exit 1
    fi

    # shellcheck disable=SC2154
    for index in ${vm_list}; do
        echo "INFO: Running on seat-${name}-${index}"
        ip=$(jq --raw-output '.ip' set/${name}/seat-${name}-${index}.json)
        ssh -i "${script_base_dir}/set/${name}/ssh" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "root@${ip}" -- "${command[@]}"
    done

    exit 0
}

run_help() {
    cat <<EOF
seatctl <global options> run -- <command>

Executes a command remotely.

Command options:
  --help      XXX
EOF
}

run_main "$@"