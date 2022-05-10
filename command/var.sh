#!/bin/bash

function var_main() {
    local var_name
    local var_value

    while test "$#" -gt 0; do
        local parameter=$1
        shift

        case "${parameter}" in
            --name)
                var_name=$1
            ;;
            --value)
                var_value=$1
            ;;
            --help)
                var_help
                exit 0
            ;;
            *)
                error "Wrong parameters"
                generate_help
                exit 1
            ;;
        esac

        shift
    done

    if test -z "${var_name}"; then
        error "Variable name not specified"
        var_help
        exit 1
    fi
    if test -z "${var_value}"; then
        error "Variable value not specified"
        var_help
        exit 1
    fi

    # shellcheck disable=SC2154
    for index in ${vm_list}; do
        # shellcheck disable=SC2154
        info "Running on seat-${name}-${index}"

        # shellcheck disable=SC2154
        ip=$(jq --raw-output '.ip' "${script_base_dir}/set/${name}/seat-${name}-${index}.json")

        echo "export ${var_name}=${var_value}" | ssh -i "${script_base_dir}/set/${name}/ssh" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "root@${ip}" "cat >/etc/profile.d/${var_name}.sh"
    done


    exit 0
}

var_help() {
    cat <<EOF
seatctl <global options> var <command options>

Add global environment variable.

Command options:
  --name      Name of variable (required)
  --value     Value of variable (required)
  --help      Show help
EOF
}

var_main "$@"