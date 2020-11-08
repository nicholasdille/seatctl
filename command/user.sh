#!/bin/bash

function user_add() {
    while test "$#" -gt 0; do
        local parameter=$1
        shift

        case "${parameter}" in
            add)
                user_add "$@"
                exit 0
            ;;
            reset)
                user_reset "$@"
                exit 0
            ;;
            --)
                break
            ;;
            *)
                error "Unknown parameter <${parameter}> for command"
            ;;
        esac

        shift
    done

    run_on_set hostname

    exit 0
}

function user_reset() {
    echo reset
}

function user_main() {
    while test "$#" -gt 0; do
        local parameter=$1
        shift

        case "${parameter}" in
            add)
                user_add "$@"
                exit 0
            ;;
            reset)
                user_reset "$@"
                exit 0
            ;;
            --)
                break
            ;;
            *)
                error "Unknown parameter <${parameter}> for command"
            ;;
        esac

        shift
    done

    exit 0
}

user_main "$@"