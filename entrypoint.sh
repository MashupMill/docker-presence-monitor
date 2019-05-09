#!/usr/bin/env bash

if [[ ! -z "$DEBUG_ENTRY" ]]; then
    set -x
fi

cleanup() {
    wait
    service bluetooth stop
    service dbus stop
    exec echo
}

trap "cleanup" EXIT

service dbus start
service bluetooth start

touch /config/.public_name_cache

# if first parameter is a valid command, then we will execute that
# otherwise we will just send all the parameters to monitor.sh
if [[ ! -z "$1" ]] && ( [[ -f "$1" ]] || command -v $1 &> /dev/null );  then
    "${@}"
    exit $?
else
    monitor "${@}"
    exit $?
fi

