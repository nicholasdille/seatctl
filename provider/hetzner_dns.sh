#!/bin/bash

if test -z "${HETZNER_DNS_API_TOKEN}"; then
    error "Provider hetzner_dns requires environment variable HETZNER_DNS_API_TOKEN"
    exit 1
fi
export HETZNER_DNS_API_TOKEN

function get_dns_zone_id() {
    local zone=$1
    if test -z "${zone}"; then
        echo "ERROR: Zone must be specified"
        exit 1
    fi

    curl "https://dns.hetzner.com/api/v1/zones" \
        --silent \
        --header "Auth-API-Token: ${HETZNER_DNS_API_TOKEN}" | \
            jq --raw-output --arg zone "${zone}" '.zones[] | select(.name == $zone) | .id'
}

function get_dns_record_id() {
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

    local id=$(get_dns_zone_id "${zone}")

    >&2 echo "VERBOSE: Checking for DNS record ${name}.${zone} of type ${type}."
    curl "https://dns.hetzner.com/api/v1/records?zone_id=${id}" \
        --silent \
        --header "Auth-API-Token: ${HETZNER_DNS_API_TOKEN}" | \
            jq --raw-output --arg name "${name}" --arg type "${type}" '.records[] | select(.name == $name and ($type == "" or .type == $type)) | .id'
}

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

    >&2 echo "VERBOSE: Checking for DNS record ${name}.${zone} of type ${type}."
    local record="$(get_dns_record_id "${zone}" "${name}" "${type}")"
    if test -z "${record}"; then
        >&2 echo "Record ${name}.${zone} of type ${type} does not exist"
        return 1
    else
        >&2 echo "Record ${name}.${zone} of type ${type} exists"
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

    local id=$(get_dns_zone_id "${zone}")

    local request="$(
        cat <<EOF
{
    "zone_id": "${id}",
    "name": "${name}",
    "type": "${type}",
    "value":"${content}"
}
EOF
    )"
    curl "https://dns.hetzner.com/api/v1/records" \
        --silent \
        --header "Auth-API-Token: ${HETZNER_DNS_API_TOKEN}" \
        --request POST \
        --data "${request}"
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

    local id=$(get_dns_record_id "${zone}" "${name}")

    curl "https://dns.hetzner.com/api/v1/records/${id}" \
        --silent \
        --header "Auth-API-Token: ${HETZNER_DNS_API_TOKEN}" \
        --request DELETE \
        --output /dev/null
}

function get_dns_record() {
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

    local id=$(get_dns_zone_id "${zone}")

    curl "https://dns.hetzner.com/api/v1/records?zone_id=${id}" \
        --silent \
        --header "Auth-API-Token: ${HETZNER_DNS_API_TOKEN}" | \
            jq --raw-output --arg name "${name}" '.records[] | select(.name == $name) | "\(.name) \(.type) \(.value)"'

}