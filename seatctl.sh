#!/bin/bash
set -o errexit

version=main
script_base_dir="$(
    dirname "$(
        readlink -f "$0"
    )"
)"

if test -f "${script_base_dir}/.env"; then
    # shellcheck disable=SC1090 source=.env
    source "${script_base_dir}/.env"
fi

# shellcheck source=lib/color.sh
source "${script_base_dir}/lib/color.sh"
# shellcheck source=lib/common.sh
source "${script_base_dir}/lib/common.sh"
# shellcheck source=lib/logging.sh
source "${script_base_dir}/lib/logging.sh"
# shellcheck source=lib/requirements.sh
source "${script_base_dir}/lib/requirements.sh"

process_requirements "${script_base_dir}/requirements.yaml"

if test -f "${script_base_dir}/.env"; then
    source "${script_base_dir}/.env"
fi

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

    ip=$(jq --raw-output '.ip' "${script_base_dir}/set/${name}/seat-${name}-${index}.json")
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
                provider_list=$1
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
            --log-level)
                LOG_LEVEL_ID="$(get_log_level_id "$1")"
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
            add|codes|dns|file|generate|install|list|local|reboot|remove|run|tls|shutdown|ssh|sudo|start|type|user|var|wait)
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

    verbose "name=${name}"

    if test -z "${provider_list}"; then
        if test -f "${script_base_dir}/set/${name}/providers.txt"; then
            provider_list=$(
                cat "${script_base_dir}/set/${name}/providers.txt"
            )
        fi
    fi

    verbose "provider=${provider_list}"
    verbose "command=${command}"

    providers="$(echo "${provider_list}" | tr ',' ' ')"
    for provider in ${providers}; do
        if test -f "${script_base_dir}/provider/${provider}.sh"; then
            # shellcheck disable=SC1090
            source "${script_base_dir}/provider/${provider}.sh"
        else
            error "Provider <${provider}> does not exist"
        fi
    done

    if test -z "${vm_list}"; then
        if test -z "${vm_count}"; then
            if test -d "${script_base_dir}/set/${name}" && test "$(find "${script_base_dir}/set/${name}" -name "seat-${name}-*.json" | wc -l)" -gt 0; then
                ROOT_DIR=$(git rev-parse --show-toplevel)
                vm_list=$(
                    find "${script_base_dir}/set/${name}" -name "seat-${name}-*.json" | \
                        sed -E "s|${ROOT_DIR}/||" | \
                        cut -d/ -f3 | \
                        cut -d. -f1 | \
                        cut -d- -f3 | \
                        sort -V
                )
            else
                error "You must specify either --list or --count or run on an existing set."
                exit 1
            fi
        fi

        if test -z "${vm_list}"; then
            vm_list=$(
                seq \
                    "${vm_start_index}" \
                    "$(( "${vm_start_index}" + "${vm_count}" - 1 ))"
            )
        fi
    fi

    verbose "vm_start_index=${vm_start_index}"
    verbose "vm_count=${vm_count}"
    # shellcheck disable=SC2116
    verbose "vm_list=$(echo "${vm_list}" | tr '\n' ' ')"

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
  --log-level       Verbosity (info, verbose, debug)
  --help            Show help
  --version         Show version

Commands:
  add         Create new virtual machines
  dns         Create DNS records for VMs
  file        Transfer file with VMs
  generate    Generate password list to use with <user> subcommand
  list        List virtual machines
  local       Add local configuration
  reboot      Reboot virtual machines
  remove      Remove virtual machines
  run         Executes a command on the VMs
  tls         Issue and renew certificates
  shutdown    Shutdown virtual machines
  ssh         Enter remote shell using SSH
  start       Power on virtual machines
  sudo        Set sudo without password for user on VM
  type        Change type of VMs in powered off state
  user        Configure user account on VM
  wait        Wait for SSH to be available on VM
EOF
}

main "$@"