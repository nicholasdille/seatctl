#!/bin/bash

if test -z "${HCLOUD_CONTEXT}" && test -z "${HCLOUD_TOKEN}"; then
    error "Provider hcloud requires either environment variable HCLOUD_CONTEXT or HCLOUD_TOKEN"
    exit 1
fi
export HCLOUD_CONTEXT
export HCLOUD_TOKEN

# shellcheck disable=SC2154
HCLOUD="${script_base_dir}/bin/hcloud"

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

    if test "$(${HCLOUD} server list --selector seatctl-set="${name}",seatctl-index="${index}" --output noheader | wc -l)" -gt 0; then
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

    if test "$(${HCLOUD} ssh-key list --selector seatctl-set="${name}" --output noheader | wc -l)" -eq 0; then
        ${HCLOUD} ssh-key create \
            --name "seatctl-set-${name}" \
            --public-key-from-file "${ssh_key}"
        ${HCLOUD} ssh-key add-label "seatctl-set-${name}" \
            seatctl-set="${name}"
    fi

    local hcloud_ssh_fingerprint
    hcloud_ssh_fingerprint=$(${HCLOUD} ssh-key list --selector seatctl-set="${name}" --output columns=fingerprint | tail -n 1)
    local local_ssh_fingerprint
    local_ssh_fingerprint=$(ssh-keygen -l -E md5 -f set/${name}/ssh | cut -d' ' -f2 | cut -d':' -f2-)
    if test "${hcloud_ssh_fingerprint}" != "${local_ssh_fingerprint}"; then
        error "SSH key fingerprints do not match"
        exit 1
    fi

    if ! exists_virtual_machine "${name}" "${index}"; then
        ${HCLOUD} server create \
            --name "seat-${name}-${index}" \
            --location fsn1 \
            --type cx21 \
            --image ubuntu-20.04 \
            --ssh-key "seatctl-set-${name}" \
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
        verbose "Fetching IP address for index ${index} in set ${name}..."
        ${HCLOUD} server list --selector seatctl-set="${name}",seatctl-index="${index}" --output columns=ipv4 | tail -n +2
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
        ${HCLOUD} server delete "seat-${name}-${index}"
    fi
}