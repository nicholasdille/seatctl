#!/bin/bash
set -o errexit -o pipefail

FILE=seats.json
COUNT="$( jq --raw-output '.count' "${FILE}" )"
DOMAIN="$( jq --raw-output '.domain' "${FILE}" )"
ROOT_TOKEN="$( jq --raw-output '.gitlab_admin_token' "${FILE}" )"

for SEAT_INDEX in $(seq 0 $((COUNT - 1))); do
    NAME="seat${SEAT_INDEX}"
    echo "### ${NAME}"

    SEAT_GITLAB_TOKEN="$( jq --raw-output --arg index "${SEAT_INDEX}" '.seats[] | select(.index == $index) | .gitlab_token' "${FILE}" )"
    #scp fix_runner.sh ${NAME}:/opt/
    scp fix_webdav.sh ${NAME}:/opt/

    #ssh ${NAME} env SEAT_INDEX=${SEAT_INDEX} DOMAIN=${DOMAIN} SEAT_GITLAB_TOKEN=${SEAT_GITLAB_TOKEN} bash /opt/fix_runner.sh
    ssh ${NAME} env SEAT_INDEX=${SEAT_INDEX} DOMAIN=${DOMAIN} SEAT_GITLAB_TOKEN=${SEAT_GITLAB_TOKEN} bash /opt/fix_webdav.sh
done