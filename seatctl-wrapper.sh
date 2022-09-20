#!/bin/bash
set -o errexit

ZONE="inmylab.de"

./seatctl.sh "$@" add
./seatctl.sh "$@" wait
# TODO: Wait for cloud-init to finish
./seatctl.sh "$@" tls --zone "${ZONE}" --command get --sleep 30
./seatctl.sh "$@" tls --zone "${ZONE}" --command copy
./seatctl.sh "$@" run -- docker-setup install / docker