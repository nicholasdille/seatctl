#!/bin/bash
set -o errexit

NAME=$1
START=$2
COUNT=$3
ZONE=$4
DIR=$5

if test -z "${NAME}" || test -z "${START}" || test -z "${COUNT}" || test -z "${ZONE}"; then
    echo "Usage: $0 <name> <start> <count> <zone>"
    exit 1
fi

success="$(echo -e "\u2713")"
failure="$(echo -e "\u2717")"

INDEX=0
while test "${INDEX}" -lt "${COUNT}"; do
    SEAT_INDEX=$(( INDEX + START ))
    if ! test -f set/${NAME}/seat-${NAME}-${SEAT_INDEX}.json; then
        continue
    fi
    IP="$(jq --raw-output '.ip' set/${NAME}/seat-${NAME}-${SEAT_INDEX}.json)"
    DOMAIN="seat${SEAT_INDEX}.${ZONE}"

    echo -e -n "${DOMAIN}"

    DNS_IP="$(dig +short ${DOMAIN})"
    if test "${DNS_IP}" == "${IP}"; then
        echo -e -n ";${success}"
    else
        echo -e -n ";${failure}"
    fi

    DNS_IP="$(dig +short foo.${DOMAIN} | tail -n 1)"
    if test "${DNS_IP}" == "${IP}"; then
        echo -e -n ";${success}"
    else
        echo -e -n ";${failure}"
    fi

    if test -f "set/${NAME}/seat-${NAME}-${SEAT_INDEX}.key"; then
        echo -e -n ";${success}"
    else
        echo -e -n ";${failure}"
    fi

    if ssh -i set/${NAME}/ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR root@${IP} true; then
        echo -e -n ";${success}"
    else
        echo -e -n ";${failure}"
    fi

    if ssh -i set/${NAME}/ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR root@${IP} test -f ssl/seat.key; then
        echo -e -n ";${success}"
    else
        echo -e -n ";${failure}"
    fi

    if test "$(curl -so /dev/null -w "%{http_code}" https://traefik.${DOMAIN})" == "401"; then
        echo -e -n ";${success}"
    else
        echo -e -n ";${failure}"
    fi

    if curl -sfo /dev/null https://${DOMAIN}; then
        echo -e -n ";${success}"
    else
        echo -e -n ";${failure}"
    fi

    if curl -sfo /dev/null https://gitlab.${DOMAIN}; then
        echo -e -n ";${success}"
    else
        echo -e -n ";${failure}"
    fi

    if test "$(ssh -i set/${NAME}/ssh -o ConnectTimeout=1 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR root@${IP} bash --login -c "\"docker compose --project-directory container-slides/160_gitlab_ci/000_rollout ps --format json 2>&1\"" | grep -v "level=warning" | jq --raw-output '.[] | select(.Service == "runner") | .State')" == "running"; then
        echo -e -n ";${success}"
    else
        echo -e -n ";${failure}"
    fi

    echo

    INDEX=$(( INDEX + 1 ))
done \
| column --table --separator ';' --table-columns 'Seat,DNS1,DNS2,CRT1,SSH,CRT2,traefik,info,gitlab,runner'