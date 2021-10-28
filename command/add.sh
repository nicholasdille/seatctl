#!/bin/bash

function add_main() {
    assert_functions "Missing VM provider" create_virtual_machine get_virtual_machine_ip

    while test "$#" -gt 0; do
        local parameter=$1
        shift

        case "${parameter}" in
            --help)
                add_help
                exit 0
            ;;
            *)
                error "Wrong parameter ${parameter}."
                add_help
                exit 1
            ;;
        esac

        shift
    done

    # shellcheck disable=SC2154
    mkdir -p "${script_base_dir}/set/${name}"
    # shellcheck disable=SC2154
    if ! test -f "${script_base_dir}/set/${name}/ssh"; then
        # shellcheck disable=SC2154
        ssh-keygen -f "${script_base_dir}/set/${name}/ssh" -N ''
    fi

    # shellcheck disable=SC2154
    for index in ${vm_list}; do
        create_virtual_machine "${name}" "${index}" "${script_base_dir}/set/${name}/ssh.pub"

        local ip
        ip=$(get_virtual_machine_ip "${name}" "${index}")
        if test -n "${ip}"; then
            info "Set ${name}, seat ${index}, ip ${ip}."

            jq \
                --null-input \
                --arg name "${name}" \
                --arg index "${index}" \
                --arg ip "${ip}" \
                '{
                    "name": $name,
                    "index": $index,
                    "ip": $ip
                }' \
                >"${script_base_dir}/set/${name}/seat-${name}-${index}.json"
        else
            warning "Got no IP address for seat ${index} in set ${name}"
        fi
    done

    exit 0
}

add_help() {
    cat <<EOF
seatctl <global options> add <command options>

Adds a new virtual machine. Requires virtual machine provider.

Command options:
  --help    Show help
EOF
}

add_main "$@"