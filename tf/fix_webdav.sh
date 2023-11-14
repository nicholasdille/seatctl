#!/bin/bash
set -o errexit -o pipefail

test -n "${SEAT_INDEX}"
test -n "${DOMAIN}"
test -n "${SEAT_GITLAB_TOKEN}"

source /etc/profile.d/vars.sh

git -C /root/container-slides pull
docker compose --project-directory=/root/container-slides/160_gitlab_ci/000_rollout build nginx
docker compose --project-directory=/root/container-slides/160_gitlab_ci/000_rollout up -d nginx
