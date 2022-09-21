#!/bin/bash
set -o errexit

ZONE="inmylab.de"

./seatctl.sh "$@" add
./seatctl.sh "$@" wait
./seatctl.sh "$@" tls --zone "${ZONE}" --command get --sleep 30
./seatctl.sh "$@" tls --zone "${ZONE}" --command copy
./seatctl.sh "$@" wait
./seatctl.sh "$@" run -- cloud-init status --wait
./seatctl.sh "$@" wait
./seatctl.sh "$@" run -- docker-setup update
./seatctl.sh "$@" run -- docker-setup upgrade
./seatctl.sh "$@" run -- docker-setup install / docker