#!/bin/bash

list_main() {
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
        echo "Set Index Provisioned Available"

        # shellcheck disable=SC2154
        for index in ${vm_list}; do
            >&2 echo -e -n "\rChecking seat ${index}"

            echo -n "${name} ${index}"
            if exists_virtual_machine "${name}" "${index}"; then
                echo -n " yes"
            else
                echo -n " no"
            fi

            ip=$(jq --raw-output '.ip' set/${name}/seat-${name}-${index}.json)
            if ssh -i set/${name}/ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR root@${ip} true; then
                echo " yes"
            else
                echo " no"
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