#!/bin/bash

function user_main() {
    local command
    local prefix=seat
    local password_file

    while test "$#" -gt 0; do
        local parameter=$1
        shift

        case "${parameter}" in
            --command)
                command=$1
            ;;
            --prefix)
                prefix=$1
            ;;
            --password-file)
                password_file=$1
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

    # shellcheck disable=SC2154
    for index in ${vm_list}; do
        info "Running on seat-${name}-${index}"

        ip=$(jq --raw-output '.ip' set/${name}/seat-${name}-${index}.json)

        case "${command}" in
            add)
                run_on_seat "${name}" "${index}" useradd --create-home --shell /bin/bash "${prefix}${index}"
            ;;
            remove)
                run_on_seat "${name}" "${index}" userdel "${prefix}${index}"
            ;;
            lock)
                run_on_seat "${name}" "${index}" usermod --lock "${prefix}${index}"
            ;;
            unlock)
                run_on_seat "${name}" "${index}" usermod --unlock "${prefix}${index}"
            ;;
            reset)
                if test -z "${password_file}"; then
                    echo "ERROR: Password file must be specified"
                    exit 1
                fi
                if ! test -f "${password_file}"; then
                    echo "ERROR: Password file does not exist"
                    exit 1
                fi

                local password
                password=$(cat "${password_file}" | cut -d';' -f3 | head -n "${index}")
                run_on_seat "${name}" "${index}" "echo ${prefix}${index}:${password} | chpasswd"
            ;;
        esac
    done

    exit 0
}

user_main "$@"