#!/bin/bash

function tls_main() {
    local zone
    local command
    local server=letsencrypt
    local sleep=300
    local force=false

    while test "$#" -gt 0; do
        case "$1" in
            --zone)
                shift
                zone=$1
            ;;
            --command)
                shift
                command=$1
            ;;
            --server)
                shift
                server=$1
            ;;
            --sleep)
                shift
                sleep=$1
            ;;
            --force)
                force=true
            ;;
            --help)
                tls_help
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
        error "Zone not specified"
        tls_help
        exit 1
    fi
    if test -z "${command}"; then
        error "Command not specified"
        tls_help
        exit 1
    fi

    force_param=
    if ${force}; then
        force_param=--force
    fi

    # shellcheck disable=SC2154
    for index in ${vm_list}; do
        # shellcheck disable=SC2154
        info "Processing seat-${name}-${index}"

        # shellcheck disable=SC2154
        ip=$(jq --raw-output '.ip' "${script_base_dir}/set/${name}/seat-${name}-${index}.json")

        case "${command}" in
            get)
                export HETZNER_Token="${HETZNER_DNS_API_TOKEN}"
                "${HOME}/.acme.sh/acme.sh" --issue \
                    --server "${server}" \
                    --dns dns_hetzner \
                    --domain "seat${index}.${zone}" \
                    --domain "*.seat${index}.${zone}" \
                    --domain "*.gitlab.seat${index}.${zone}" \
                    --dnssleep "${sleep}" \
                    --key-file       "${script_base_dir}/set/${name}/seat-${name}-${index}.key" \
                    --cert-file      "${script_base_dir}/set/${name}/seat-${name}-${index}.crt" \
                    --ca-file        "${script_base_dir}/set/${name}/seat-${name}-${index}.ca" \
                    --fullchain-file "${script_base_dir}/set/${name}/seat-${name}-${index}.chain" \
                    ${force_param}
            ;;
            renew)
                export HETZNER_Token="${HETZNER_DNS_API_TOKEN}"
                "${HOME}/.acme.sh/acme.sh" --renew \
                    --server "${server}" \
                    --dns dns_hetzner \
                    --domain "seat0.inmylab.de" \
                    --dnssleep "${sleep}" \
                    ${force_param}
            ;;
            copy)
                scp \
                    -i "${script_base_dir}/set/${name}/ssh" \
                    -o StrictHostKeyChecking=no \
                    -o UserKnownHostsFile=/dev/null \
                    -o LogLevel=ERROR \
                    "${script_base_dir}/set/${name}/seat-${name}-${index}.key" \
                    "root@${ip}:/root/ssl/seat.key"
                scp \
                    -i "${script_base_dir}/set/${name}/ssh" \
                    -o StrictHostKeyChecking=no \
                    -o UserKnownHostsFile=/dev/null \
                    -o LogLevel=ERROR \
                    "${script_base_dir}/set/${name}/seat-${name}-${index}.crt" \
                    "root@${ip}:/root/ssl/seat.crt"
                scp \
                    -i "${script_base_dir}/set/${name}/ssh" \
                    -o StrictHostKeyChecking=no \
                    -o UserKnownHostsFile=/dev/null \
                    -o LogLevel=ERROR \
                    "${script_base_dir}/set/${name}/seat-${name}-${index}.ca" \
                    "root@${ip}:/root/ssl/seat.ca"
                scp \
                    -i "${script_base_dir}/set/${name}/ssh" \
                    -o StrictHostKeyChecking=no \
                    -o UserKnownHostsFile=/dev/null \
                    -o LogLevel=ERROR \
                    "${script_base_dir}/set/${name}/seat-${name}-${index}.chain" \
                    "root@${ip}:/root/ssl/seat.chain"
            ;;
            *)
                echo "ERROR: Unknown command <${command}>"
                exit 1
            ;;
        esac
    done


    exit 0
}

tls_help() {
    cat <<EOF
seatctl <global options> var <command options>

Manage certificates.

Command options:
  --zone       DNS zone for records (required)
  --command    Sub-command to execute (required)
  --ca         CA to use (defaults to letsencrypt)
  --help       Show help

Sub-commands:
  get       Retrieve certificate
  renew     Renew certificate
  copy      Copy certificate to VM
EOF
}

tls_main "$@"