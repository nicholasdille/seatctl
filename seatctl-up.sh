#!/bin/bash
set -o errexit

NAME=$1
COUNT=$2
ZONE=$3

if test -z "${NAME}" || test -z "${COUNT}" || test -z "${ZONE}"; then
    echo "Usage: $0 <name> <count> <zone>"
    exit 1
fi

set -- --provider hcloud,hetzner_dns --name "${NAME}" --start 0 --count "${COUNT}"

if ! test -f "set/${NAME}/passwords.csv"; then
    ./seatctl.sh "$@" generate --zone "${ZONE}"
fi

echo
echo "### Setting up infrastructure"
./seatctl.sh "$@" add
./seatctl.sh "$@" wait
./seatctl.sh "$@" dns --command add --zone "${ZONE}"

echo
echo "### Setting up certificate"
if test -f "${script_base_dir}/set/${name}/seat-${name}-${index}.key"; then
    ./seatctl.sh "$@" tls --zone "${ZONE}" --command get --sleep 30
    ./seatctl.sh "$@" tls --zone "${ZONE}" --command copy
fi

echo
echo "### Waiting for cloud-init to finish"
./seatctl.sh "$@" wait
./seatctl.sh "$@" run -- cloud-init status --wait
./seatctl.sh "$@" wait

echo
echo "### Setting up user and variables"
if ! ./seatctl.sh "$@" run -- grep -q seat /etc/passwd; then
    ./seatctl.sh "$@" user --command add
fi
./seatctl.sh "$@" user --command lock
./seatctl.sh "$@" user --command var
./seatctl.sh "$@" dns --command var --zone "${ZONE}"

echo
echo "### Setting up tools"
if ! ./seatctl.sh "$@" run -- docker version >/dev/null 2>&1; then
    ./seatctl.sh "$@" run -- docker-setup update
    ./seatctl.sh "$@" run -- docker-setup upgrade
    ./seatctl.sh "$@" run -- docker-setup --default install /
fi

echo
echo "### Setting up repository"
if ! ./seatctl.sh "$@" run -- test -d container-slides; then
    ./seatctl.sh "$@" run -- git clone https://github.com/nicholasdille/container-slides
else
    ./seatctl.sh "$@" run -- "cd container-slides && git reset --hard && git pull"
fi

echo
echo "### Starting deployment"
./seatctl.sh "$@" run -- container-slides/160_gitlab_ci/000_rollout/bootstrap.sh