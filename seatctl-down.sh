#!/bin/bash
set -o errexit

NAME=$1
COUNT=$2
ZONE=$3

if test -z "${NAME}" || test -z "${COUNT}" || test -z "${ZONE}"; then
    echo "Usage: $0 <name> <count> <zone>"
    exit 1
fi

set -- --provider hcloud --name "${NAME}" --start 0 --count "${COUNT}"

./seatctl.sh "$@" dns --command remove --zone "${ZONE}"
./seatctl.sh "$@" remove
