FROM alpine:latest

ARG MONITOR_BRANCH=master

VOLUME /config

RUN apk add --no-cache \
        openrc \
        coreutils \
        procps \
        gawk \
        git \
        bash \
        curl \
        mosquitto \
        mosquitto-clients \
        bc \
        bluez \
        bluez-deprecated \
        bluez-btmon \
    && git clone git://github.com/andrewjfreyer/monitor /monitor

COPY entrypoint.sh /entrypoint.sh
ENV PREF_CONFIG_DIR=/config \
    PREF_ARRIVAL_SCAN_ATTEMPTS=1 \
    PREF_DEPART_SCAN_ATTEMPTS=2 \
    PREF_BEACON_EXPIRATION=240 \
    PREF_MINIMUM_TIME_BETWEEN_SCANS=15 \
    PREF_PASS_FILTER_ADV_FLAGS_ARRIVE=".*" \
    PREF_PASS_FILTER_MANUFACTURER_ARRIVE=".*" \
    PREF_FAIL_FILTER_ADV_FLAGS_ARRIVE="NONE" \
    PREF_FAIL_FILTER_MANUFACTURER_ARRIVE="NONE"

RUN cd /monitor \
    && git checkout $MONITOR_BRANCH \
    && touch .pids \
    && touch .previous_version \
    # make things executable
    && ln -s /monitor/monitor.sh /usr/local/bin/monitor \
    && chmod a+x monitor.sh \
    && chmod a+x /entrypoint.sh \
    # link the public name cache to the config directory ... i think there's a bug in monitor.sh where it doesn't consistently reference the same path to this...sometimes it looks in $base_directory (which we have as /config) and sometimes its in the app root (i.e. /monitor)
    && ln -s /config/.public_name_cache .public_name_cache \
    # no systemctl ... this keeps the error out about it
    && sed -i 's|systemctl is-active.*|SERVICE_ACTIVE=false|' support/init \
    # default config directory to come from an environment variable
    && sed -i 's|PREF_CONFIG_DIR='"''"'|PREF_CONFIG_DIR="${PREF_CONFIG_DIR}"|' support/argv \
    # Setting up openrc to work in docker ... https://github.com/dockage/alpine/blob/master/3.9/openrc/Dockerfile
    # Start copy/paste from dockage
    # Disable getty's
    && sed -i 's/^\(tty\d\:\:\)/#\1/g' /etc/inittab \
    && sed -i \
        # Change subsystem type to "docker"
        -e 's/#rc_sys=".*"/rc_sys="docker"/g' \
        # Allow all variables through
        -e 's/#rc_env_allow=".*"/rc_env_allow="\*"/g' \
        # Start crashed services
        -e 's/#rc_crashed_stop=.*/rc_crashed_stop=NO/g' \
        -e 's/#rc_crashed_start=.*/rc_crashed_start=YES/g' \
        # Define extra dependencies for services
        -e 's/#rc_provide=".*"/rc_provide="loopback net"/g' \
        /etc/rc.conf \
    # Remove unnecessary services
    && rm -f /etc/init.d/hwdrivers \
            /etc/init.d/hwclock \
            /etc/init.d/hwdrivers \
            /etc/init.d/modules \
            /etc/init.d/modules-load \
            /etc/init.d/modloop \
    # Can't do cgroups
    && sed -i 's/\tcgroup_add_service/\t#cgroup_add_service/g' /lib/rc/sh/openrc-run.sh \
    && sed -i 's/VSERVER/DOCKER/Ig' /lib/rc/sh/init.sh \
    # END copy/paste from dockage
    # don't set hostname since docker sets it
    && sed -i 's/hostname $opts/# hostname $opts/g' /etc/init.d/hostname \
    # don't mount tmpfs since not privileged
    && sed -i 's/mount -t tmpfs/# mount -t tmpfs/g' /lib/rc/sh/init.sh \
    # Start up openrc
    && mkdir /run/openrc \
    && touch /run/openrc/softlevel \
    && openrc

WORKDIR /monitor

ENTRYPOINT ["/entrypoint.sh"]


# docker build --tag mashupmill/presence-monitor . && docker run --rm -it --name monitor --net host --privileged --volume ~/monitor/config:/config mashupmill/presence-monitor -b -r
