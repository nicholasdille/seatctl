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

if ! test -f "set/${NAME}/passwords.csv"; then
    ./seatctl.sh "$@" generate --zone "${ZONE}"
fi

echo
echo "### Setting up infrastructure for seat ${START}"
./seatctl.sh "$@" add
./seatctl.sh "$@" wait
./seatctl.sh "$@" dns --command add --zone "${ZONE}"

echo
echo "### Setting up certificate for seat ${START}"
if ! test -f "set/${NAME}/seat-${NAME}-${START}.key"; then
    ./seatctl.sh "$@" tls --zone "${ZONE}" --command get --sleep 10
    ./seatctl.sh "$@" tls --zone "${ZONE}" --command copy
fi

echo
echo "### Waiting for cloud-init to finish for seat ${START}"
./seatctl.sh "$@" wait
./seatctl.sh "$@" run -- cloud-init status --wait
./seatctl.sh "$@" wait
./seatctl.sh "$@" run -- "while test -f /var/run/reboot-required; do sleep 10; done"
./seatctl.sh "$@" wait

echo
echo "### Setting up user and variables for seat ${START}"
if ! ./seatctl.sh "$@" run -- grep -q seat /etc/passwd; then
    ./seatctl.sh "$@" user --command add
fi
./seatctl.sh "$@" user --command reset
./seatctl.sh "$@" user --command lock
./seatctl.sh "$@" user --command sudo
./seatctl.sh "$@" user --command docker-group
./seatctl.sh "$@" user --command var
./seatctl.sh "$@" dns --command var --zone "${ZONE}"

echo
echo "### Setting up tools for seat ${START}"
if ! ./seatctl.sh "$@" run -- docker version >/dev/null 2>&1; then
    ./seatctl.sh "$@" run -- update-alternatives --set iptables /usr/sbin/iptables-legacy
    ./seatctl.sh "$@" run -- docker-setup update
    ./seatctl.sh "$@" run -- docker-setup upgrade
    ./seatctl.sh "$@" run -- docker-setup --default install
fi

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
    ./seatctl.sh "$@" run -- container-slides/160_gitlab_ci/000_rollout/bootstrap.sh
    exit 0
fi

echo
echo "### Setting up user repository for seat ${START}"
if ! ./seatctl.sh "$@" run -- test -d /home/seat/container-slides; then
    ./seatctl.sh "$@" run -- sudo -u seat git clone https://github.com/nicholasdille/container-slides /home/seat/container-slides
else
    ./seatctl.sh "$@" run -- sudo -u seat git -C /home/seat/container-slides reset --hard
    ./seatctl.sh "$@" run -- sudo -u seat git -C /home/seat/container-slides pull
fi
