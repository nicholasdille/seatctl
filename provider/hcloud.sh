#!/bin/bash

if test -z "${HCLOUD_CONTEXT}" ; then
    error "Provider hcloud requires environment variable HCLOUD_CONTEXT"
    exit 1
fi
export HCLOUD_CONTEXT

if test -z "${HCLOUD_DNS_CONTEXT}" ; then
    info "Assuming the same hcloud context for DNS"
fi
export HCLOUD_DNS_CONTEXT

function exists_ssh_key() {
    local name=$1

    if test -z "${name}"; then
        error "Name of virtual machine must be supplied"
        exit 1
    fi

    test "$(hcloud --context "${HCLOUD_CONTEXT}" ssh-key list --selector seatctl-set="${name}" --output noheader | wc -l)" -eq 0
}

function check_ssh_key() {
    local name=$1

    if test -z "${name}"; then
        error "Name of virtual machine must be supplied"
        exit 1
    fi

    local hcloud_ssh_fingerprint
    hcloud_ssh_fingerprint=$(hcloud --context "${HCLOUD_CONTEXT}" ssh-key list --selector seatctl-set="${name}" --output columns=fingerprint | tail -n 1)
    local local_ssh_fingerprint
    local_ssh_fingerprint=$(ssh-keygen -l -E md5 -f "${script_base_dir}/set/${name}/ssh" | cut -d' ' -f2 | cut -d':' -f2-)
    
    test "${hcloud_ssh_fingerprint}" == "${local_ssh_fingerprint}"
}

function create_ssh_key() {
    local name=$1
    local ssh_key=$2

    if test -z "${name}"; then
        error "Name of virtual machine must be supplied"
        exit 1
    fi
    if test -z "${ssh_key}"; then
        error "Path and filename to SSH public key must be supplied"
        exit 1
    fi
    if ! test -f "${ssh_key}"; then
        error "Path and filename to SSH public key must exist"
        exit 1
    fi

    if exists_ssh_key "${name}"; then
        hcloud --context "${HCLOUD_CONTEXT}" ssh-key create \
            --name "seatctl-set-${name}" \
            --public-key-from-file "${ssh_key}"
        hcloud --context "${HCLOUD_CONTEXT}" ssh-key add-label "seatctl-set-${name}" \
            seatctl-set="${name}"
    fi

    if ! check_ssh_key "${name}"; then
        error "SSH key fingerprints do not match"
        exit 1
    fi
}

function remove_ssh_key() {
    local name=$1

    if test -z "${name}"; then
        error "Name of virtual machine must be supplied"
        exit 1
    fi

    if exists_ssh_key "${name}"; then
        hcloud --context "${HCLOUD_CONTEXT}" ssh-key delete "seatctl-set-${name}"
    fi
}

function exists_virtual_machine() {
    local name=$1
    local index=$2

    if test -z "${name}"; then
        error "Name of virtual machine must be supplied"
        exit 1
    fi
    if test -z "${index}"; then
        error "Index of virtual machine must be supplied"
        exit 1
    fi

    if test "$(hcloud --context "${HCLOUD_CONTEXT}" server list --selector seatctl-set="${name}",seatctl-index="${index}" --output noheader | wc -l)" -gt 0; then
        return 0
    fi

    return 1
}

function create_virtual_machine() {
    local name=$1
    local index=$2
    local ssh_key=$3

    if test -z "${name}"; then
        error "Name of virtual machine must be supplied"
        exit 1
    fi
    if test -z "${index}"; then
        error "Index of virtual machine must be supplied"
        exit 1
    fi
    if test -z "${ssh_key}"; then
        error "Path and filename to SSH public key must be supplied"
        exit 1
    fi
    if ! test -f "${ssh_key}"; then
        error "Path and filename to SSH public key must exist"
        exit 1
    fi
    
    create_ssh_key "${name}" "${ssh_key}"

    if ! exists_virtual_machine "${name}" "${index}"; then
        local user_data_file="${script_base_dir}/cloud-config/${name}.yaml"
        if test -f "${user_data_file}"; then
            local user_data_param="--user-data-from-file ${user_data_file}"
        else
            local user_data_param="--user-data-from-file ${script_base_dir}/cloud-config/default.yaml"
        fi
        debug "user_data_param=${user_data_param}."

        # shellcheck disable=SC2086
        hcloud --context "${HCLOUD_CONTEXT}" server create \
            --name "seat-${name}-${index}" \
            --location fsn1 \
            --type cx42 \
            --image ubuntu-24.04 \
            --ssh-key "seatctl-set-${name}" \
            ${user_data_param} \
            --label seatctl-set="${name}" \
            --label seatctl-index="${index}"

    else
        verbose "Virtual machine with index ${index} in set ${name} already exists"
    fi
}

function get_virtual_machine_ip() {
    local name=$1
    local index=$2

    if test -z "${name}"; then
        error "Name of virtual machine must be supplied"
        exit 1
    fi
    if test -z "${index}"; then
        error "Index of virtual machine must be supplied"
        exit 1
    fi

    if exists_virtual_machine "${name}" "${index}"; then
        >&2 echo "Fetching IP address for index ${index} in set ${name}..."
        hcloud --context "${HCLOUD_CONTEXT}" server list --selector seatctl-set="${name}",seatctl-index="${index}" --output columns=ipv4 | tail -n +2
    fi
}

function remove_virtual_machine() {
    local name=$1
    local index=$2

    if test -z "${name}"; then
        error "Name of virtual machine must be supplied"
        exit 1
    fi
    if test -z "${index}"; then
        error "Index of virtual machine must be supplied"
        exit 1
    fi

    if exists_virtual_machine "${name}" "${index}"; then
        hcloud --context "${HCLOUD_CONTEXT}" server delete "seat-${name}-${index}"
    fi
}

function start_virtual_machine() {
    local name=$1
    local index=$2

    if test -z "${name}"; then
        error "Name of virtual machine must be supplied"
        exit 1
    fi
    if test -z "${index}"; then
        error "Index of virtual machine must be supplied"
        exit 1
    fi

    if exists_virtual_machine "${name}" "${index}"; then
        hcloud --context "${HCLOUD_CONTEXT}" server poweron "seat-${name}-${index}"
    fi
}

function stop_virtual_machine() {
    local name=$1
    local index=$2

    if test -z "${name}"; then
        error "Name of virtual machine must be supplied"
        exit 1
    fi
    if test -z "${index}"; then
        error "Index of virtual machine must be supplied"
        exit 1
    fi

    if exists_virtual_machine "${name}" "${index}"; then
        hcloud --context "${HCLOUD_CONTEXT}" server poweroff "seat-${name}-${index}"
    fi
}

function shutdown_virtual_machine() {
    local name=$1
    local index=$2

    if test -z "${name}"; then
        error "Name of virtual machine must be supplied"
        exit 1
    fi
    if test -z "${index}"; then
        error "Index of virtual machine must be supplied"
        exit 1
    fi

    if exists_virtual_machine "${name}" "${index}"; then
        hcloud --context "${HCLOUD_CONTEXT}" server shutdown "seat-${name}-${index}"
    fi
}

function restart_virtual_machine() {
    local name=$1
    local index=$2

    if test -z "${name}"; then
        error "Name of virtual machine must be supplied"
        exit 1
    fi
    if test -z "${index}"; then
        error "Index of virtual machine must be supplied"
        exit 1
    fi

    if exists_virtual_machine "${name}" "${index}"; then
        hcloud --context "${HCLOUD_CONTEXT}" server reboot "seat-${name}-${index}"
    fi
}

function change_type_virtual_machine() {
    local name=$1
    local index=$2
    local type=$3

    if test -z "${name}"; then
        error "Name of virtual machine must be supplied"
        exit 1
    fi
    if test -z "${index}"; then
        error "Index of virtual machine must be supplied"
        exit 1
    fi

    if exists_virtual_machine "${name}" "${index}"; then
        hcloud --context "${HCLOUD_CONTEXT}" server change-type "seat-${name}-${index}" "${type}"
    fi
}

function exists_dns_record() {
    local zone=$1
    if test -z "${zone}"; then
        error "Zone must be specified"
        exit 1
    fi
    local name=$2
    if test -z "${name}"; then
        error "Name must be specified"
        exit 1
    fi
    local type=$3
    if test -z "${type}"; then
        error "Type must be specified"
        exit 1
    fi

    verbose "Checking for DNS record ${name}.${zone} of type ${type}."
    if hcloud --context "${HCLOUD_DNS_CONTEXT}" zone rrset describe "${zone}" "${name}" "${type}" >/dev/null 2>&1; then
        verbose "Record ${name}.${zone} of type ${type} does not exist"
        return 1
    else
        verbose "Record ${name}.${zone} of type ${type} exists"
        return 0
    fi
}

function create_dns_record() {
    local zone=$1
    if test -z "${zone}"; then
        error "Zone must be specified"
        exit 1
    fi
    local name=$2
    if test -z "${name}"; then
        error "Name must be specified"
        exit 1
    fi
    local type=$3
    if test -z "${type}"; then
        error "Type must be specified"
        exit 1
    fi
    local content=$4
    if test -z "${content}"; then
        error "Content must be specified"
        exit 1
    fi

    hcloud --context "${HCLOUD_DNS_CONTEXT}" zone add-records "${zone}" "${name}" "${type}" --record="${content}"
}

function remove_dns_record() {
    local zone=$1
    if test -z "${zone}"; then
        error "Zone must be specified"
        exit 1
    fi
    local name=$2
    if test -z "${name}"; then
        error "Name must be specified"
        exit 1
    fi
    local type=$3
    if test -z "${type}"; then
        error "Type must be specified"
        exit 1
    fi

    hcloud --context "${HCLOUD_DNS_CONTEXT}" zone rrset delete "${zone}" "${name}" "${type}"
}

function get_dns_record() {
    local zone=$1
    if test -z "${zone}"; then
        error "Zone must be specified"
        exit 1
    fi
    local name=$2
    if test -z "${name}"; then
        error "Name must be specified"
        exit 1
    fi
    local type=$3
    if test -z "${type}"; then
        error "Type must be specified"
        exit 1
    fi

    hcloud --context "${HCLOUD_DNS_CONTEXT}" zone rrset describe "${zone}" "${name}" "${type}" --output=json | jq -r '"\(.name) \(.type) \(.records[].value)"'
}