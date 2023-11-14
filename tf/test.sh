#!/bin/bash
set -o errexit -o pipefail

OK=✔
NOT_OK=𐄂

FILE=seats.json
COUNT="$( jq --raw-output '.count' "${FILE}" )"
DOMAIN="$( jq --raw-output '.domain' "${FILE}" )"
ROOT_TOKEN="$( jq --raw-output '.gitlab_admin_token' "${FILE}" )"

for INDEX in $(seq 0 $((COUNT - 1))); do
    NAME="seat${INDEX}"

    echo -n "Testing ${NAME}..."

    if ssh "${NAME}" true >/dev/null 2>&1; then
        echo -n " SSH${OK}"
    else
        echo " SSH${NOT_OK}"
        continue
    fi

    HCLOUD_IP="$( hcloud server ip "${NAME}" )"
    DNS_IP="$( dig +short "${NAME}.${DOMAIN}" )"
    if test "${HCLOUD_IP}" == "${DNS_IP}"; then
        echo -n " DNS${OK}"
    else
        echo " DNS${NOT_OK}"
        continue
    fi
    DNS_IP="$( dig +short "foo.${NAME}.${DOMAIN}" | tail -n 1 )"
    if test "${HCLOUD_IP}" == "${DNS_IP}"; then
        echo -n " Wildcard${OK}"
    else
        echo " Wildcard${NOT_OK}"
        continue
    fi

    if curl -sSo /dev/null "https://gitlab.${NAME}.${DOMAIN}" 2>/dev/null; then
        echo -n " GitLab${OK}"
    else
        echo " GitLab${NOT_OK}"
        continue
    fi

    if curl -sSo /dev/null "https://${NAME}.${DOMAIN}" 2>/dev/null; then
        echo -n " TLS${OK}"
    else
        echo " TLS${NOT_OK}"
        continue
    fi

    ROOT_USERNAME="$(
        curl -sSfH "Private-Token: ${ROOT_TOKEN}" "https://gitlab.${NAME}.${DOMAIN}/api/v4/user" \
        | jq --raw-output '.username'
    )"
    if test "${ROOT_USERNAME}" == "root"; then
        echo -n " Root${OK}"
    else
        echo " Root${NOT_OK}"
        continue
    fi

    SEAT_TOKEN="$( jq --raw-output --arg index "${INDEX}" '.seats[] | select(.index == $index) | .gitlab_token' "${FILE}" )"
    SEAT_USERNAME="$(
        curl -sSfH "Private-Token: ${SEAT_TOKEN}" "https://gitlab.${NAME}.${DOMAIN}/api/v4/user" \
        | jq --raw-output '.username'
    )"
    if test "${SEAT_USERNAME}" == "seat"; then
        echo -n " Seat${OK}"
    else
        echo " Seat${NOT_OK}"
        continue
    fi

    RUNNER_COUNT="$(
        curl -sSfH "Private-Token: ${SEAT_TOKEN}" "https://gitlab.${NAME}.${DOMAIN}/api/v4/runners/all" \
        | jq --raw-output '. | length'
    )"
    if test "${RUNNER_COUNT}" -gt 0; then
        echo -n " Runner${OK}"
    else
        echo " Runner${NOT_OK}"
        continue
    fi

    PROJECT="$(
        curl -sSfH "Private-Token: ${SEAT_TOKEN}" https://gitlab.${NAME}.${DOMAIN}/api/v4/projects \
        | jq --raw-output '.[].name_with_namespace'
    )"
    if test "${PROJECT}" == "seat / demo"; then
        echo -n " Project${OK}"
    else
        echo " Project${NOT_OK}"
        continue
    fi

    if curl -sSo /dev/null "https://traefik.${NAME}.${DOMAIN}"; then
        echo -n " Traefik${OK}"
    else
        echo " Traefik${NOT_OK}"
        continue
    fi

    if curl -sSo /dev/null "https://webdav.${NAME}.${DOMAIN}"; then
        echo -n " WebDAV${OK}"
    else
        echo " WebDAV${NOT_OK}"
        continue
    fi

    echo -n " Load:<"
    ssh "${NAME}" cat /proc/loadavg 2>/dev/null | cut -d' ' -f1-3 | tr -d '\n'
    echo -n ">"

    echo
done