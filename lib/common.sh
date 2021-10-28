#!/bin/bash

function function_exists() {
    local name="$1"
    if declare -F | grep --quiet " $1$"; then
        return 0
    else
        return 1
    fi
}

function assert_functions() {
    local message="$1"
    shift

    while test "$#" -gt 0; do
        local name="$1"
        shift

        if ! function_exists "${name}"; then
            error "${message}"
            exit 1
        fi
    done
}