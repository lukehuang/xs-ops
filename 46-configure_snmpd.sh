#!/bin/bash

set -vx
set -eu

# Configure SNMP
yum --disablerepo=citrix --enablerepo=base install -y net-snmp net-snmp-utils || true

grep -iq 'dport 161.*ACCEPT' /etc/sysconfig/iptables || \
  sed -r '
    /ESTABLISHED,RELATED/ a -A RH-Firewall-1-INPUT -p udp -m udp --dport 161 -j ACCEPT
    ' /etc/sysconfig/iptables
