#!/bin/bash

function user_main() {
    local command

    while test "$#" -gt 0; do
        local parameter=$1
        shift

        case "${parameter}" in
            --command)
                command=$1
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
                password=$(cat "set/${name}/passwords.csv" | grep ";seat${index};" | cut -d';' -f3)
                if test -z "${password}"; then
                    error "No password found"
                    continue
                fi
                echo password=${password}
                run_on_seat "${name}" "${index}" "echo seat${index}:${password} | chpasswd"
            ;;
        esac
    done

    exit 0
}

user_help() {
    cat <<EOF
seatctl <global options> user <command options>

Sets sudo without password.

Command options:
  --command    XXX (required)
  --help       XXX

Sub-commands:
  add       XXX
  remove    XXX
  lock      XXX
  unlock    XXX
  reset     XXX
EOF
}

user_main "$@"