#!/bin/bash

set -eu
set -xv

# Set NTP Servers in /etc/ntp.conf
service ntpd stop || true
printf "%s\n" "${ntp_servers[@]}" | xargs -i ntpdate {}

grep -iq '^\ *server' /etc/ntp.conf && \
  sed -r -i '/^\ *server.*/d' /etc/ntp.conf
r_join ntp_servers[@] $'\n' | sed 's@^@server @' >> /etc/ntp.conf

service ntpd restart
# sleep 10
# set +e
# service ntpd status
# ntpq -c ntpversion  "$(hostname -f)"
# ntptrace -n
# ntptime  -rc
# ntpq -c peers       "$(hostname -f)"
# ntpq -c lpeers      "$(hostname -f)"
# ntpq -c readlist    "$(hostname -f)"
# date
