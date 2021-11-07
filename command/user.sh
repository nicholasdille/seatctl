#!/bin/bash

function user_main() {
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
            --help)
                user_help
                exit 0
            ;;
            *)
                error "Wrong parameters"
                user_help
                exit 1
            ;;
        esac

        shift
    done

    if test -z "${command}"; then
        error "Command not specified"
        exit 1
    fi
    if test "${command}" == "test" && test -z "${zone}"; then
        error "Command test requires parameter zone"
        exit 1
    fi

    # shellcheck disable=SC2154
    for index in ${vm_list}; do
        info "Running on seat-${name}-${index}"

        case "${command}" in
            add)
                run_on_seat "${name}" "${index}" useradd --create-home --shell /bin/bash "seat${index}"
            ;;
            remove)
                run_on_seat "${name}" "${index}" userdel "seat${index}"
            ;;
            lock)
                run_on_seat "${name}" "${index}" usermod --lock "seat${index}"
            ;;
            unlock)
                run_on_seat "${name}" "${index}" usermod --unlock "seat${index}"
            ;;
            reset)
                local password
                password=$(cat "${script_base_dir}/set/${name}/passwords.csv" | grep ";seat${index};" | cut -d';' -f3)
                if test -z "${password}"; then
                    error "No password found"
                    continue
                fi
                run_on_seat "${name}" "${index}" "echo seat${index}:${password} | chpasswd"
            ;;
            test)
                local password
                password=$(cat "${script_base_dir}/set/${name}/passwords.csv" | grep ";seat${index};" | cut -d';' -f3)
                if test -z "${password}"; then
                    error "No password found"
                    continue
                fi
                if ! sshpass -p "${password}" ssh -o StrictHostKeyChecking=no -o LogLevel=Error seat${index}@seat${index}.${zone} true; then
                    error "Failed to test index ${index}"
                fi
            ;;
        esac
    done

    exit 0
}

user_help() {
    cat <<EOF
seatctl <global options> user <command options>

Configure user account on VM.

Command options:
  --command    Sub-command to execute (required)
  --help       Show help

Sub-commands:
  add       Create user account
  remove    Remove user account
  lock      Lock user account (deny login)
  unlock    Unlock user account (allow login)
  reset     Reset password
  test      Test authentication
EOF
}

user_main "$@"