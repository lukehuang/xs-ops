#!/bin/bash

set -xv
set -u

mgmt_ip=$(xe host-list uuid="$this_host_uuid" params=address --minimal)
mgmt_ip="${mgmt_ip:-127.0.1.1}"
mgmt_bridge=$( xe network-list uuid=$(xe pif-list management=true params=network-uuid --minimal) params=bridge --minimal )

# TODO, rewrite this to statistically guess hostname
# TODO, domain name is possibly unset
_hostname="${_hostname:-localhost.localdomain}"
[[ -z $_hostname || $_hostname = localhost* ]] && _hostname=$(grep host-name /var/lib/dhclient/dhclient-"$mgmt_bridge".leases | awk -F'[ |\"]' '{print $6}' | sort -u)
[[ -z $_hostname || $_hostname = localhost* ]] && _hostname=$(xe host-list uuid="$this_host_uuid" params=hostname --minimal)
[[ -z $_hostname || $_hostname = localhost* ]] && _hostname=$(hostname)
[[ -z $_hostname || $_hostname = localhost* ]] && _hostname=$(</etc/hostname)
[[ -z $_hostname || $_hostname = localhost* ]] && _hostname=$(sed -nr '/^\ *HOSTNAME=/ s/^\ *HOSTNAME/_hostname/p' /etc/sysconfig/network > /tmp/_hostname; source /tmp/_hostname; echo "$_hostname" )
[[ -z $_hostname || $_hostname = localhost* ]] && _hostname=$(hostname -f)
[[ -z $_hostname || $_hostname = localhost* ]] && _hostname=$(hostname -s) 
[[ -z $_hostname || $_hostname = localhost* ]] && _hostname=$(xe host-list uuid="$this_host_uuid" params=name-label --minimal)
[[ -z $_hostname || $_hostname = localhost* ]] && _hostname=$( perl -MSocket -Wle 'print scalar gethostbyaddr inet_aton(+pop), AF_INET;' "$mgmt_ip" )
[[ -z $_hostname || $_hostname = localhost* ]] && _hostname=$(getent hosts "$mgmt_ip" | awk '{print $2}')

HOSTNAME="$_hostname"

[[ $HOSTNAME = *.* ]] && DOMAINNAME="${HOSTNAME#*.}"
HOSTNAME="${HOSTNAME%%.*}" || true

DOMAINNAME="${DOMAINNAME:-$(hostname -d)}"
DOMAINNAME="${DOMAINNAME:-localdomain}"

set -e

# ---- Set hostname and domainname ----
HOSTNAME= hostname "$HOSTNAME"
HOSTNAME= sysctl -w kernel.hostname="$HOSTNAME"
echo "$DOMAINNAME"  > /etc/domainname
echo "$HOSTNAME"    > /etc/hostname

if grep -iq "^\ *$mgmt_ip" /etc/hosts; then
  sed -r -i '/'"$mgmt_ip"'/d' /etc/hosts
fi

if grep -iq "$HOSTNAME" /etc/hosts; then
  sed -r -i '/'"$HOSTNAME"'/d' /etc/hosts
fi

cat <<EOHOSTS >> /etc/hosts
$mgmt_ip    $HOSTNAME.$DOMAINNAME  $HOSTNAME
::1         $HOSTNAME.$DOMAINNAME  $HOSTNAME
EOHOSTS

# Verify the hostname is set
HOSTNAME= hostname
HOSTNAME= hostname -s  
HOSTNAME= hostname -f
HOSTNAME= hostname -d

# Set hostname via xe
xe host-param-set         \
  name-label="$HOSTNAME"  \
  uuid="$this_host_uuid"

xe host-set-hostname-live        \
     host-uuid="$this_host_uuid" \
     host-name="$(hostname -s)"  \
     hostname="$(hostname -s)"
