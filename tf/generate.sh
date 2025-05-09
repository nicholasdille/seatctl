#!/bin/bash
set -o errexit -o pipefail

: "${SET_NAME:=$(date +%Y%m%d)}"
: "${COUNT:=1}"
: "${LOCATION:=nbg1}"
: "${SERVER_TYPE:=cx41}"
: "${DOMAIN:=inmylab.de}"
: "${BOOTSTRAP_DIR:=160_gitlab_ci/000_rollout}"

if test -f seats.json; then
    echo "ERROR: File seats.json already exists."
    exit 1
fi

function generate_code() {
    local chars=(A B C D E F G H J K L M N P Q R S T U V W X Y Z 2 3 4 5 6 7 8 9)
    local length=6

    local max="${#chars[*]}"

    local code=""
    while test "${length}" -gt 0; do
        code="${code}${chars[$((RANDOM % max))]}"

        length=$((length - 1))
    done

    echo -n "${code}"
}

result="$(
    jq \
        --null-input \
        --arg name "${SET_NAME}" \
        --arg count "${COUNT}" \
        --arg location "${LOCATION}" \
        --arg server_type "${SERVER_TYPE}" \
        --arg domain "${DOMAIN}" \
        --arg gitlab_admin_password "$(openssl rand -hex 32)" \
        --arg gitlab_admin_token "$(openssl rand -hex 32)" \
        --arg bootstrap_directory "${BOOTSTRAP_DIR}" \
        '
        {
            "name": $name,
            "count": $count,
            "location": $location,
            "server_type": $server_type,
            "domain": $domain,
            "gitlab_admin_password": $gitlab_admin_password,
            "gitlab_admin_token": $gitlab_admin_token,
            "bootstrap_directory": $bootstrap_directory,
            "seats": []
        }
        '
)"

for INDEX in $(seq 0 $((COUNT-1))); do
    result="$(
        echo "${result}" | jq \
            --arg index "${INDEX}" \
            --arg password "$(openssl rand -hex 32)" \
            --arg code "$(generate_code)" \
            --arg gitlab_token "$(openssl rand -hex 32)" \
            --arg webdav_pass_dev "$(openssl rand -hex 32)" \
            --arg webdav_pass_live "$(openssl rand -hex 32)" \
            '
            . as $all |
            $all.seats +=
            [{
                "index": $index,
                "password": $password,
                "code": $code,
                "gitlab_token": $gitlab_token,
                "webdav_pass_dev": $webdav_pass_dev,
                "webdav_pass_live": $webdav_pass_live
            }]
            '
    )"
done

echo "${result}" >seats.json

cat seats.json \
| jq --raw-output '
        .seats[] |
        "\nHost seat\(.index).inmylab.de\nUser seat\nCode \(.code)\nPassword \(.password)"
    ' \
>seats.txt

cat seats.json \
| jq --raw-output '
        .seats[] |
        "Username: seat\(.index)\nCode: \(.code)\n"
    ' \
>seat-codes.txt
