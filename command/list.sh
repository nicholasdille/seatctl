#!/bin/bash

list_main() {
    assert_functions "Missing VM provider" exists_virtual_machine

    while test "$#" -gt 0; do
        local parameter=$1
        shift

        case "${parameter}" in
            --help)
                list_help
                exit 0
            ;;
            *)
                error "Wrong parameter ${parameter}."
                list_help
                exit 1
            ;;
        esac

        shift
    done

    (
        echo "Set Index Provisioned IP Available"

        # shellcheck disable=SC2154
        for index in ${vm_list}; do
            >&2 echo -e -n "\rChecking seat ${index}"

            # Set Index
            echo -n "${name} ${index}"

            # Provisioned
            if exists_virtual_machine "${name}" "${index}"; then
                echo -n " yes"
            else
                echo -n " no"
            fi

            # Available
            if test -f "${script_base_dir}/set/${name}/seat-${name}-${index}.json"; then
                ip=$(jq --raw-output '.ip' ${script_base_dir}/set/${name}/seat-${name}-${index}.json)
                if ssh -i "${script_base_dir}/set/${name}/ssh" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR root@${ip} true; then
                    echo -n " ${ip} yes"
                else
                    echo -n " ${ip} no"
                fi
            fi
            echo
        done
        >&2 echo -e -n "\r"
    ) | column -t

    exit 0
}

list_help() {
    cat <<EOF
seatctl <global options> list

List virtual machine.

Command options:
  --help      Show help
EOF
}

list_main "$@"