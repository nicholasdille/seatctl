#!/bin/bash
set -o errexit

NAME=$1
START=$2
COUNT=$3
ZONE=$4
DIR=$5

if test -z "${NAME}" || test -z "${START}" || test -z "${COUNT}" || test -z "${ZONE}"; then
    echo "Usage: $0 <name> <start> <count> <zone> [<dir>]"
    exit 1
fi

if test "${COUNT}" -gt 1; then
    ./seatctl.sh --provider hcloud,hetzner_dns --name "${NAME}" --start "${START}" --count "${COUNT}" bootstrap

    declare -a pids
    for INDEX in $(seq 1 ${COUNT}); do
        #$0 $1 $((START+INDEX-1)) 1 $4 $5 >"set/${NAME}/seat-foo-$((INDEX-1))-up.log" 2>&1 &
        $0 $1 $((START+INDEX-1)) 1 $4 $5
        #pids+=( $! )
    done

    running_pids="${#pids[@]}"
    while test "${running_pids}" -gt 0; do
        sleep 1

        running_pids=0
        for pid in ${pids[@]}; do
            if test -d "/proc/${pid}"; then
                running_pids=$((running_pids+1))
            fi
        done
        echo -n -e "\rRunning ${running_pids} deployment(s)..."
    done
    echo

    ./seatctl.sh "$@" local --command ssh
    #./seatctl.sh "$@" user --command test --zone inmylab.de
    exit
fi

set -- --provider hcloud,hetzner_dns --name "${NAME}" --start "${START}" --count "${COUNT}"

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
    ./seatctl.sh "$@" run -- container-slides/${DIR}/restart.sh
fi