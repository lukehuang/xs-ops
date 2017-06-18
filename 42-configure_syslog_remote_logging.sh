#!/bin/bash

set -eu
set -xv

# Configure Syslog for remote logging
echo "*.*             @$syslog_server" >>/etc/syslog.conf
service syslog restart

sleep 2
service syslog status
