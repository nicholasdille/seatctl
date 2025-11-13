#!/bin/bash
set -o errexit

NAME=$1
START=$2
COUNT=$3
ZONE=$4
DIR=$5

if test -z "${NAME}" || test -z "${START}" || test -z "${COUNT}" || test -z "${ZONE}"; then
    echo "Usage: $0 <name> <start> <count> <zone> <git-dir>"
    exit 1
fi

if test "${COUNT}" -gt 1; then
    ./seatctl.sh --provider hcloud --name "${NAME}" --start "${START}" --count "${COUNT}" bootstrap

    for INDEX in $(seq 1 ${COUNT}); do
        $0 $1 $((START+INDEX-1)) 1 $4 $5
    done

    exit
fi

set -- --provider hcloud --name "${NAME}" --start "${START}" --count "${COUNT}"

git -C "${DIR}" remote remove "seat${START}" >/dev/null 2>&1 || true
git -C "${DIR}" remote add "seat${START}" "https://gitlab.seat${START}.${ZONE}/seat/demo"
