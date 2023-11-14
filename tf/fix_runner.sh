#!/bin/bash
set -o errexit -o pipefail

test -n "${SEAT_INDEX}"
test -n "${DOMAIN}"
test -n "${SEAT_GITLAB_TOKEN}"

source /etc/profile.d/vars.sh

RUNNER_COUNT="$(
    curl \
        --url "https://gitlab.${DOMAIN}/api/v4/runners/all" \
        --silent \
        --show-error \
        --header "Private-Token: ${SEAT_GITLAB_TOKEN}" \
    | jq --raw-output '. | length'
)"
if test "${RUNNER_COUNT}" -gt 0; then
    echo "Runner is already running"
    exit
fi

REGISTRATION_TOKEN="$(
    curl \
        --url "https://gitlab.${DOMAIN}/api/v4/user/runners" \
        --silent \
        --show-error \
        --request POST \
        --header "Private-Token: ${SEAT_GITLAB_TOKEN}" \
        --header "Content-Type: application/json" \
        --data '{"runner_type": "instance_type", "run_untagged": true}' \
    | jq --raw-output '.token'
)"
export REGISTRATION_TOKEN
docker compose --project-directory=/root/container-slides/160_gitlab_ci/000_rollout up -d runner
