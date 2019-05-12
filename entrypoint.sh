#!/usr/bin/env bash

if [[ ! -z "$DEBUG_ENTRY" ]]; then
    set -x
fi

cleanup() {
    if [[ $pid -gt 0 ]]; then
        kill $pid
    fi
    service bluetooth stop
    service dbus stop
    exec echo
}

trap "cleanup" EXIT INT TERM

service dbus start
service bluetooth start

touch "${PREF_CONFIG_DIR}/.public_name_cache"

# create config files

## address_blacklist
if [[ ! -f "/${PREF_CONFIG_DIR}/address_blacklist" ]]; then
    tee "/${PREF_CONFIG_DIR}/address_blacklist" > /dev/null  <<EOF
#LIST MAC ADDRESSES TO IGNORE, ONE PER LINE:
${ADDRESS_BLACKLIST}
EOF
fi

## behavior_preferences
if [[ ! -f "/${PREF_CONFIG_DIR}/behavior_prerences" ]]; then
    tee "/${PREF_CONFIG_DIR}/behavior_prerences" > /dev/null  <<EOF
# ---------------------------
#                               
# BEHAVIOR PREFERENCES
#                               
# ---------------------------

# Note: For docker by default we will just expect these to be container environment variables
EOF
fi

## known_beacon_addresses
if [[ ! -f "/${PREF_CONFIG_DIR}/known_beacon_addresses" ]]; then
    tee "/${PREF_CONFIG_DIR}/known_beacon_addresses" > /dev/null  <<EOF
# ---------------------------
#
# BEACON MAC ADDRESS LIST; REQUIRES NAME
#
#   Format: 00:00:00:00:00:00 Nickname #comments
# ---------------------------
${KNOWN_BEACON_ADDRESSES}
EOF
fi

## known_static_addresses
if [[ ! -f "/${PREF_CONFIG_DIR}/known_static_addresses" ]]; then
    tee "/${PREF_CONFIG_DIR}/known_static_addresses" > /dev/null  <<EOF
# ---------------------------
#
# STATIC MAC ADDRESS LIST
#
# 00:00:00:00:00:00 Alias #comment
# ---------------------------
${KNOWN_STATIC_ADDRESSES}
EOF
fi

## known_static_addresses
if [[ ! -f "/${PREF_CONFIG_DIR}/mqtt_preferences" ]]; then
    tee "/${PREF_CONFIG_DIR}/mqtt_preferences" > /dev/null  <<EOF
# ---------------------------
#                               
# MOSQUITTO PREFERENCES
#                               
# ---------------------------

# IP ADDRESS OR HOSTNAME OF MQTT BROKER
mqtt_address="\${MQTT_ADDRESS}"

# MQTT BROKER USERNAME
mqtt_user="\${MQTT_USER}"

# MQTT BROKER PASSWORD
mqtt_password="\${MQTT_PASSWORD}"

# MQTT PUBLISH TOPIC ROOT 
mqtt_topicpath="\${MQTT_TOPICPATH}"

# PUBLISHER IDENTITY 
mqtt_publisher_identity="\${MQTT_PUBLISHER_IDENTITY}"

# MQTT PORT 
mqtt_port="\${MQTT_PORT}"

# MQTT CERTIFICATE FILE
mqtt_certificate_path="\${MQTT_CERTIFICATE_PATH}"

#MQTT VERSION (EXAMPLE: 'mqttv311')
mqtt_version="\${MQTT_VERSION}"
EOF
fi

# if first parameter is a valid command, then we will execute that
# otherwise we will just send all the parameters to monitor.sh
if [[ ! -z "$1" ]] && ( [[ -f "$1" ]] || command -v $1 &> /dev/null );  then
    "${@}"
    exit $?
else
    monitor "${@}" &
    pid=$!
    wait
    exit $?
fi

