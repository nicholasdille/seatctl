#!/bin/bash

if test -z "${CF_API_EMAIL}" || test -z "${CF_API_KEY}"; then
    error "Provider cloudflare requires both environment variables CF_API_EMAIL and CF_API_KEY"
    exit 1
fi
export CF_API_EMAIL
export CF_API_KEY

function exists_dns_record() {
    local zone=$1
    if test -z "${zone}"; then
        echo "ERROR: Zone must be specified"
        exit 1
    fi
    local name=$2
    if test -z "${name}"; then
        echo "ERROR: Name must be specified"
        exit 1
    fi
    local type=$3
    if test -z "${type}"; then
        echo "ERROR: Type must be specified"
        exit 1
    fi

    if test "$(flarectl dns list --zone "${zone}" --name "${name}.${zone}" --type "${type}" | wc -l)" -eq 2; then
        return 1
    else
        return 0
    fi
}

function create_dns_record() {
    local zone=$1
    if test -z "${zone}"; then
        echo "ERROR: Zone must be specified"
        exit 1
    fi
    local name=$2
    if test -z "${name}"; then
        echo "ERROR: Name must be specified"
        exit 1
    fi
    local type=$3
    if test -z "${type}"; then
        echo "ERROR: Type must be specified"
        exit 1
    fi
    local content=$4
    if test -z "${content}"; then
        echo "ERROR: Content must be specified"
        exit 1
    fi

    flarectl dns create-or-update --zone "${zone}" --name ${name} --type "${type}" --content "${content}"
}

function remove_dns_record() {
    local zone=$1
    if test -z "${zone}"; then
        echo "ERROR: Zone must be specified"
        exit 1
    fi
    local name=$2
    if test -z "${name}"; then
        echo "ERROR: Name must be specified"
        exit 1
    fi
    local type=$3
    if test -z "${type}"; then
        echo "ERROR: Type must be specified"
        exit 1
    fi

    local id
    id=$(
        flarectl --json dns list --zone "${zone}" --name "${name}.${zone}" --type "${type}" | \
            jq --raw-output '.[].ID'
    )
    if test -z "${id}"; then
        echo "ERROR: Unable to determine ID for deletion"
        exit 1
    fi

    flarectl dns delete --zone "${zone}" --id "${id}"
}