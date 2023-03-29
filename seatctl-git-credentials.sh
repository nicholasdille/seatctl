#!/bin/bash
set -o errexit

NAME=$1
START=$2
COUNT=$3
ZONE=$4
DIR=$5
TOKEN=$6

if test -z "${NAME}" || test -z "${START}" || test -z "${COUNT}" || test -z "${ZONE}"; then
    echo "Usage: $0 <name> <start> <count> <zone> <dir-not-used> <token>"
    exit 1
fi

if test "${COUNT}" -gt 1; then
    ./seatctl.sh --provider hcloud,hetzner_dns --name "${NAME}" --start "${START}" --count "${COUNT}" bootstrap

    for INDEX in $(seq 1 ${COUNT}); do
        $0 $1 $((START+INDEX-1)) 1 $4 $5 $6
    done

    exit
fi

set -- --provider hcloud,hetzner_dns --name "${NAME}" --start "${START}" --count "${COUNT}"

sed -i "/gitlab.seat${START}.${ZONE}/d" "${HOME}/.git-credentials"
echo "https://root:${TOKEN}@gitlab.seat${START}.${ZONE}" >>"${HOME}/.git-credentials"
