#!/bin/bash

LOG_LEVEL_ID=0

INFO=0
VERBOSE=1
DEBUG=2

# shellcheck disable=SC2034
INFO_COLOR=DEFAULT
# shellcheck disable=SC2034
VERBOSE_COLOR=DEFAULT
# shellcheck disable=SC2034
DEBUG_COLOR=YELLOW

function get_log_level_id() {
    local level=$1

    case "${level,,}" in
        info)
            echo -n ${INFO}
        ;;
        verbose)
            echo -n ${VERBOSE}
        ;;
        debug)
            echo -n ${DEBUG}
        ;;
        *)
            echo "ERROR: Unknown log level <${level}>."
        ;;
    esac
}

function log() {
    local level=$1
    local message=$2

    local level_id
    level_id="$(get_log_level_id "${level}")"
    if test "${level_id}" -le ${LOG_LEVEL_ID}; then
        local color="${level^^}_COLOR"
        echo_color "${!color}" "${level^^}: ${message}"
    fi
}

function info() {
    log INFO "$@"
}

function verbose() {
    log VERBOSE "$@"
}

function debug() {
    log DEBUG "$@"
}

function error() {
    local message=$1

    echo_color RED "ERROR: ${message}"
}