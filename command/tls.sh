#!/bin/bash

function tls_main() {
    local zone
    local command
    local server=letsencrypt
    local force=false

    while test "$#" -gt 0; do
        local parameter=$1
        shift

        case "${parameter}" in
            --zone)
                zone=$1
            ;;
            --command)
                command=$1
            ;;
            --server)
                server=$1
            ;;
            --force)
                force=$1
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
                    --dnssleep 300 \
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
                    --dnssleep 300 \
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
  --zone      XXX (required)
  --command   XXX (required)
  --server    XXX
  --help      Show help
EOF
}

tls_main "$@"