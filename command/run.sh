#!/bin/bash

function run_main() {
    local parallel=false
    local test=false

    while test "$#" -gt 0; do
        local parameter=$1
        shift

        case "${parameter}" in
            --help)
                run_help
                exit 0
            ;;
            --parallel)
                parallel=true
            ;;
            --test)
                test=true
            ;;
            --)
                break
            ;;
            *)
                error "Unknown parameter <${parameter}> for command"
                run_help
                exit 1
            ;;
        esac

    done
    command=("$@")

    if test "${#command[@]}" -eq 0; then
        error "Command must be specified"
        exit 1
    fi

    # shellcheck disable=SC2154
    if ! test -f "${script_base_dir}/set/${name}/ssh"; then
        error "Missing SSH key"
        exit 1
    fi

    processes=()
    # shellcheck disable=SC2154
    for index in ${vm_list}; do
        info "Running on seat-${name}-${index}"
        ip=$(jq --raw-output '.ip' "${script_base_dir}/set/${name}/seat-${name}-${index}.json")

        if ${test}; then
            command=("sleep" "$(shuf -i 1-10 -n 1)")
        fi

        if ${parallel}; then
            echo "$(date +"[%Y-%m-%d %H:%M:%S]") ${command[*]}" >>"${script_base_dir}/set/${name}/seat-${name}-${index}.log"
            ssh -i "${script_base_dir}/set/${name}/ssh" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "root@${ip}" -- "${command[@]}" >>"${script_base_dir}/set/${name}/seat-${name}-${index}.log" 2>&1 &
            processes+=("$!")
        else
            ssh -i "${script_base_dir}/set/${name}/ssh" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "root@${ip}" -- "${command[@]}"
        fi
    done

    if ${parallel}; then
        while true; do
            echo -e -n "\rWaiting for background processes to finish..."

            count=0
            for PID in "${processes[@]}"; do
                if ps -p "${PID}" >/dev/null; then
                    count=$(( count + 1 ))
                fi
            done
            echo -e -n " ${count} running"
            if test "${count}" -eq 0; then
                break
            fi

            sleep 1
        done
        echo
    fi

    exit 0
}

run_help() {
    cat <<EOF
seatctl <global options> run -- <command>

Executes a command remotely.

Command options:
  --help      Show help
EOF
}

run_main "$@"