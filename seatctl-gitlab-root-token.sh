#!/bin/bash
set -o errexit

NAME=$1
START=$2
COUNT=$3
ZONE=$4
DIR=$5
TOKEN=$6

if test -z "${NAME}" || test -z "${START}" || test -z "${COUNT}" || test -z "${ZONE}" || test -z "${DIR}" || test -z "${TOKEN}"; then
    echo "Usage: $0 <name> <start> <count> <zone> <dir> <token>"
    exit 1
fi

if test "${COUNT}" -gt 1; then
    ./seatctl.sh --provider hcloud --name "${NAME}" --start "${START}" --count "${COUNT}" bootstrap

    for INDEX in $(seq 1 ${COUNT}); do
        $0 $1 $((START+INDEX-1)) 1 $4 $5 $6
    done

    exit
fi

set -- --provider hcloud --name "${NAME}" --start "${START}" --count "${COUNT}"

echo
echo "### Setting up repository for seat ${START}"
if ! ./seatctl.sh "$@" run -- test -d container-slides; then
    ./seatctl.sh "$@" run -- git clone https://github.com/nicholasdille/container-slides
else
    ./seatctl.sh "$@" run -- "cd container-slides && git reset --hard && git pull"
fi

if test -n "${DIR}"; then
    echo
    echo "### Starting deployment for seat ${START}"
    ./seatctl.sh "$@" run -- container-slides/${DIR}/gitlab-root-token.sh "${TOKEN}"
    exit 0
fi
