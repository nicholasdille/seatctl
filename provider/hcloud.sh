#!/bin/bash

if test -n "${HCLOUD_CONTEXT}" || test -n "${HCLOUD_TOKEN}"; then
    :
else
    error "Provider hcloud requires either environment variable HCLOUD_CONTEXT or HCLOUD_TOKEN"
    exit 1
fi

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

    if test "$(hcloud server list --selector owner=seatctl,seat-set="${name}",seat-index="${index}" --output noheader | wc -l)" -gt 0; then
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

    if test "$(hcloud ssh-key list --selector owner=seatctl,seat-set=foo --output noheader | wc -l)" -eq 0; then
        hcloud ssh-key create \
            --name "seat-${name}" \
            --public-key-from-file "${ssh_key}" \
            --label owner=seatctl \
            --label seat-set="${name}"
    fi

    if ! exists_virtual_machine "${name}" "${index}"; then
        ${HCLOUD} server create \
            --name "seat-${name}-${index}" \
            --location fsn1 \
            --type cx21 \
            --image ubuntu-20.04 \
            --ssh-key "seat-${name}" \
            --label owner=seatctl \
            --label seat-set="${name}" \
            --label seat-index="${index}"
    
    else
        info "Virtual machine with index ${index} in set ${name} already exists"
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
        hcloud server list --selector owner=seatctl,seat-set="${name}",seat-index="${index}" --output columns=ipv4 | tail -n +2
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
        hcloud server delete "seat-${name}-${index}"
    fi
}