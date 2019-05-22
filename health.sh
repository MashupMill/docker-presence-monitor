#!/usr/bin/env bash

last_msg_delay=${LAST_MSG_DELAY:-30}
now=$(date +%s)
last_time=$(cat last_msg)
echo "Time since last message: $(expr $now - $last_time) seconds"
if [[ $(expr $now - $last_time) -gt $last_msg_delay ]]; then
    exit 1
fi