#!/bin/bash
set -o errexit

script_base_dir="$(
    dirname "$(
        readlink -f "$0"
    )"
)"

if test -f "${script_base_dir}/.env"; then
    # shellcheck disable=SC1090
    source "${script_base_dir}/.env"
fi

# shellcheck source=lib/color.sh
source "${script_base_dir}/lib/color.sh"
# shellcheck source=lib/logging.sh
source "${script_base_dir}/lib/logging.sh"
# shellcheck source=lib/requirements.sh
source "${script_base_dir}/lib/requirements.sh"

process_requirements "${script_base_dir}/requirements.yaml"

function main() {
    vm_start_index=1    

    while test "$#" -gt 0; do
        local parameter
        parameter=$1
        shift

        case "${parameter}" in
            --name|-n)
                name=$1
            ;;
            --provider|-p)
                provider=$1
                if test -f "${script_base_dir}/provider/${provider}.sh"; then
                    # shellcheck disable=SC1090
                    source "${script_base_dir}/provider/${provider}.sh"
                else
                    error "Provider <${provider}> does not exist"
                fi
            ;;
            --start-index|--start|-s)
                vm_start_index=$1
                if test -n "${vm_list}"; then
                    error "Parameter --start-index and/or --count cannot be used with --list"
                fi
            ;;
            --count|-c)
                vm_count=$1
                if test -n "${vm_list}"; then
                    error "Parameter --start-index and/or --count cannot be used with --list"
                fi
            ;;
            --list|-l)
                vm_list=$1
                if test -n "${vm_start_index}" || test -n "${vm_count}"; then
                    error "Parameter --list cannot be used with --start-index and/or --count"
                fi
            ;;
            --help|-h)
                show_help
                exit 0
            ;;
            --)
                break
            ;;
            add|dns|install|list|remove|run|tls|user)
                command=${parameter}
                if ! test -f "${script_base_dir}/command/${command}.sh"; then
                    error "Command <${command}> not found"
                    exit 1
                fi
                break
            ;;
            *)
                error "Unknown parameter or command <${parameter}>"
                show_help
                exit 1
            ;;
        esac

        shift
    done

    if test -z "${name}"; then
        error "Name must be specified"
        exit 1
    fi

    info "provider=${provider}"
    info "name=${name}"
    info "command=${command}"

    if test -z "${vm_list}"; then
        vm_list=$(
            seq \
                "${vm_start_index}" \
                "$(( "${vm_start_index}" + "${vm_count}" - 1 ))"
        )
    fi

    info "vm_start_index=${vm_start_index}"
    info "vm_count=${vm_count}"
    # shellcheck disable=SC2116
    info "vm_list=$(echo "${vm_list}")"

    # shellcheck disable=SC1090
    source "${script_base_dir}/command/${command}.sh"

    show_help
}

function show_help() {
    echo HELP
}

main "$@"