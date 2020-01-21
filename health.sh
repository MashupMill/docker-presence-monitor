#!/usr/bin/env bash

# last_msg_delay=${LAST_MSG_DELAY:-30}
# now=$(date +%s)
# last_time=$(cat last_msg)
# echo "Time since last message: $(expr $now - $last_time) seconds"
# if [[ $(expr $now - $last_time) -gt $last_msg_delay ]]; then
#     exit 1
# fi

source "/monitor/support/init" > /dev/null
sleep 3 && $(which mosquitto_pub) -I "$mqtt_publisher_identity" $mqtt_version_append $mqtt_ca_file_append -L "$mqtt_url$mqtt_topicpath/$mqtt_publisher_identity/KNOWN DEVICE STATES" -m '' &
msg=$($(which mosquitto_sub) -I "$mqtt_publisher_identity" $mqtt_version_append $mqtt_ca_file_append -q 2 -L "$mqtt_url$mqtt_topicpath/$mqtt_publisher_identity/status" -C 1) 
wait
if [[ "$msg" = 'online' ]]; then
    echo 'Received "online" message'
    exit 0
fi
echo "Received '$msg' as the status"
exit 1