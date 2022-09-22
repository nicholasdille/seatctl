#!/bin/bash

function codes_main() {
    local target=../container-slides/000_introduction/10_creds/nginx/codes

    while test "$#" -gt 0; do
        local parameter=$1
        shift

        case "${parameter}" in
            --target)
                target=$1
            ;;
            --help)
                codes_help
                exit 0
            ;;
            *)
                error "Wrong parameters"
                codes_help
                exit 1
            ;;
        esac

        shift
    done

    if ! test -d "${target}"; then
        error "Target directory does not exist"
        exit 1
    fi
    if ! test -f "${script_base_dir}/set/${name}/passwords.csv"; then
        error "Credentials do not exist"
        exit 1
    fi

    info "Creating codes in ${target}"

    # shellcheck disable=SC2154
    for index in ${vm_list}; do
        info "Running on seat-${name}-${index}"

        local line
        line=$(grep ";seat${index}\." "${script_base_dir}/set/${name}/passwords.csv")
        if test -z "${line}"; then
            error "No credentials found"
            continue
        fi

        local code
        code="$(echo "${line}" | cut -d";" -f1)"

        local hostname
        hostname="$(echo "${line}" | cut -d";" -f2)"

        local username
        username="$(echo "${line}" | cut -d";" -f3)"

        local password
        password="$(echo "${line}" | cut -d";" -f4)"

        mkdir -p "${target}/${code}"
        cat <<EOF >"${target}/${code}/index.html"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
    <head>
        <meta charset="UTF-8">
        <title>Credentials</title>
        <link rel="icon" href="data:image/x-icon;," type="image/x-icon">
    </head>
    <body>
        <h1>Credentials for ${code}</h1>

        <p>Hostname: ${hostname}</p>
        <p>Username: ${username}</p>
        <p>Password: ${password}</p>
    </body>
</html>
EOF
    done

    exit 0
}

codes_help() {
    cat <<EOF
seatctl <global options> codes <command options>

Generates pages to retrieve credentials using codes.

Command options:
  --target    XXX
  --help      Show help
EOF
}

codes_main "$@"