#!/bin/bash
set -o errexit

version=main
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

function run_on_seat() {
    local name=$1
    if test -z "${name}"; then
        error "Name of virtual machine must be supplied"
        exit 1
    fi
    shift

    local index=$1
    if test -z "${index}"; then
        error "Index of virtual machine must be supplied"
        exit 1
    fi
    shift

    ip=$(jq --raw-output '.ip' set/${name}/seat-${name}-${index}.json)
    ssh -i "${script_base_dir}/set/${name}/ssh" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "root@${ip}" "$@"
}

function run_on_set() {
    if test -z "${name}"; then
        error "Name of virtual machine must be supplied"
        exit 1
    fi
    if test -z "${vm_list}"; then
        error "Name of virtual machine must be supplied"
        exit 1
    fi

    # shellcheck disable=SC2154
    for index in ${vm_list}; do
        run_on_seat "${name}" "${index}" "$@"
    done
}

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
            --start|-s)
                vm_start_index=$1
                if test -n "${vm_list}"; then
                    error "Parameter --start and/or --count cannot be used with --list"
                fi
            ;;
            --count|-c)
                vm_count=$1
                if test -n "${vm_list}"; then
                    error "Parameter --start and/or --count cannot be used with --list"
                fi
            ;;
            --list|-l)
                vm_list=$1
                if test -n "${vm_start_index}" || test -n "${vm_count}"; then
                    error "Parameter --list cannot be used with --start and/or --count"
                fi
            ;;
            --help)
                show_help
                exit 0
            ;;
            --version)
                echo "seatctl version ${version}"
                exit 0
            ;;
            --)
                break
            ;;
            add|dns|file|generate|install|list|remove|run|tls|ssh|sudo|user)
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
        if test -z "${vm_count}"; then
            error "You must specify either --list or --count."
            exit 1
        fi
        vm_list=$(
            seq \
                "${vm_start_index}" \
                "$(( "${vm_start_index}" + "${vm_count}" - 1 ))"
        )
    fi

    info "vm_start_index=${vm_start_index}"
    info "vm_count=${vm_count}"
    # shellcheck disable=SC2116
    info "vm_list=$(echo "${vm_list}" | tr '\n' ' ')"

    # shellcheck disable=SC1090
    source "${script_base_dir}/command/${command}.sh"

    show_help
}

function show_help() {
    cat <<EOF
seatctl [global options] <command> [command options]

Global options:
  --name, -n        Base name for VM management (required)
  --provider, -p    Supported provider for VM or DNS management (required for some commands)
  --start, -s       First index
  --count, -c       Total number of items (required instead of --list)
  --list, -l        List of indexes (required instead of --count)
  --help            Show help
  --version         Show version

Commands:
  add         Create new virtual machines
  dns         Create DNS records for VMs
  file        Transfer file with VMs
  generate    Generate password list to use with <user> subcommand
  list        List virtual machines
  remove      Remove virtual machines
  run         Executes a command on the VMs
  tls         NOT IMPLEMENTED
  ssh         Enter remote shell using SSH
  sudo        Set sudo without password for user on VM
  user        Configure user account on VM
EOF
}

main "$@"