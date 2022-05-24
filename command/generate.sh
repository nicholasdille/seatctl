#!/bin/bash

function generate_code() {
    local chars=(A B C D E F G H J K L M N P Q R S T U V W X Y Z 2 3 4 5 6 7 8 9)
    local length=6

    local max="${#chars[*]}"

    local code=""
    while test "${length}" -gt 0; do
        code="${code}${chars[$((RANDOM % max))]}"

        length=$((length - 1))
    done

    echo -n "${code}"
}

function generate_main() {
    local zone
    local length=32

    while test "$#" -gt 0; do
        local parameter=$1
        shift

        case "${parameter}" in
            --zone)
                zone=$1
            ;;
            --length)
                length=$1
            ;;
            --help)
                generate_help
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

    if test -z "${zone}"; then
        error "DNS zone not specified"
        generate_help
        exit 1
    fi

    mkdir -p "${script_base_dir}/set/${name}"
    echo "code;hostname;username;password" >"${script_base_dir}/set/${name}/passwords.csv"
    # shellcheck disable=SC2154
    for index in ${vm_list}; do
        local code
        code="$(generate_code)"

        local password
        password=$(openssl rand -hex "${length}")

        echo "${code};seat${index}.${zone};seat;${password}" >>"${script_base_dir}/set/${name}/passwords.csv"
    done

    exit 0
}

generate_help() {
    cat <<EOF
seatctl <global options> generate <command options>

Generates passwords.

Command options:
  --zone      DNS zone of VMs (required)
  --length    Length of passwords (optional, defaults to 32)
  --help      Show help
EOF
}

generate_main "$@"