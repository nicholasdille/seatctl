#!/bin/bash

function tls_main() {
    local zone
    local command
    local server=letsencrypt
    local sleep=300

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

    if ! test -d "${HOME}/.acme.sh"; then
        error "Missing acme.sh in home directory"
        exit 1
    fi

    # shellcheck disable=SC2154
    for index in ${vm_list}; do
        # shellcheck disable=SC2154
        info "Processing seat-${name}-${index}"

        case "${command}" in
            get)
                HETZNER_API_TOKEN="$(
                    cat ~/.config/hcloud/cli.toml \
                    | grep -A 1 "name = \"dns\"" \
                    | tail -n -1 \
                    | tr -d ' ' \
                    | cut -d= -f2 \
                    | tr -d '"'
                )"
                export HETZNER_API_TOKEN
                lego \
                    --email=webmaster@${zone} \
                    --dns=hetzner \
                    --domains="seat${index}.${zone}" \
                    --domains="*.seat${index}.${zone}" \
                    --domains="*.gitlab.seat${index}.${zone}" \
                    --accept-tos \
                    run
                cp ".lego/certificates/seat${index}.${zone}.key" "${script_base_dir}/set/${name}/seat-${name}-${index}.key"
                cp ".lego/certificates/seat${index}.${zone}.issuer.crt" "${script_base_dir}/set/${name}/seat-${name}-${index}.ca"
                cp ".lego/certificates/seat${index}.${zone}.crt" "${script_base_dir}/set/${name}/seat-${name}-${index}.chain"
                cat "${script_base_dir}/set/${name}/seat-${name}-${index}.chain" \
                | awk 'BEGIN { found = 0 } /-----BEGIN CERTIFICATE-----/ { found = 1 } found { print } /-----END CERTIFICATE-----/ { exit }' \
                >"${script_base_dir}/set/${name}/seat-${name}-${index}.crt"
            ;;
            renew)
                HETZNER_API_TOKEN="$(
                    cat ~/.config/hcloud/cli.toml \
                    | grep -A 1 "name = \"dns\"" \
                    | tail -n -1 \
                    | tr -d ' ' \
                    | cut -d= -f2 \
                    | tr -d '"'
                )"
                export HETZNER_API_TOKEN
                lego \
                    --email=webmaster@${zone} \
                    --dns=hetzner \
                    --domains="seat${index}.${zone}" \
                    --domains="*.seat${index}.${zone}" \
                    --domains="*.gitlab.seat${index}.${zone}" \
                    renew
                cp ".lego/certificates/seat${index}.${zone}.key" "${script_base_dir}/set/${name}/seat-${name}-${index}.key"
                cp ".lego/certificates/seat${index}.${zone}.issuer.crt" "${script_base_dir}/set/${name}/seat-${name}-${index}.ca"
                cp ".lego/certificates/seat${index}.${zone}.crt" "${script_base_dir}/set/${name}/seat-${name}-${index}.chain"
                cat "${script_base_dir}/set/${name}/seat-${name}-${index}.chain" \
                | awk 'BEGIN { found = 0 } /-----BEGIN CERTIFICATE-----/ { found = 1 } found { print } /-----END CERTIFICATE-----/ { exit }' \
                >"${script_base_dir}/set/${name}/seat-${name}-${index}.crt"
            ;;
            copy)
                # shellcheck disable=SC2154
                ip=$(jq --raw-output '.ip' "${script_base_dir}/set/${name}/seat-${name}-${index}.json")

                run_on_seat "${name}" "${index}" mkdir -p /root/ssl
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
  --sleep      How long to wait for DNS challenge (default: 300)
  --force      Issue certificate even if renew is not necessary
  --help       Show help

Sub-commands:
  get       Retrieve certificate
  renew     Renew certificate
  copy      Copy certificate to VM
EOF
}

tls_main "$@"