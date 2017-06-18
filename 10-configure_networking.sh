#!/bin/bash

set -vex

# convert DHCP addresses to static ones for each of the xenbr* bridges

# DHCP addresses are converted to static addresses

# Do not set MTU for the primary management interface - pool membership breaks

MTU=1500

function get_network { perl -le 'printf "%vd", (eval $ARGV[0])&(eval $ARGV[1])' "$1" "$2"; }
dns_server_list=$( awk '/nameserver /{print $2}' /etc/resolv.conf | tr  $'\n' ',' | sed 's/,$/\n/' )

xe pif-scan host-uuid="$this_host_uuid"
interfaces=( $(ifconfig -a | awk '/xenbr/{ print $1 }') )

for dev in "${interfaces[@]}"; do
  # Set interface for jumbo frames (MTU 9000)
  net_uuid=$(xe network-list bridge="$dev" params=uuid --minimal)

  pif_uuids=( $(xe network-list bridge="$dev" params=PIF-uuids --minimal | sed -r 's/\ *;\ */\n/') )
  for pif in "${pif_uuids[@]}"; do 
    is_pif_mgmt=$( xe pif-list management=true uuid="$pif" params=management --minimal )

    eth_interface=$(xe pif-list uuid="$pif" params=device --minimal)
    read -r _ state < <(ip link show dev "$eth_interface" | grep -Eio 'state\ +([^ ])+')


    # If the current PIF is the primary mgmt interface, skip
    if [[ $is_pif_mgmt = true ]] || [[ $state != 'UP' ]]; then
      echo "pif='$pif'; dev='$eth_interface'; state='$state'; is_mgmt='$is_pif_mgmt';"
      echo " skipping MTU settings"
    else 
      xe network-param-set uuid="$net_uuid" MTU="$MTU"
      ip link set dev "$eth_interface" mtu "$MTU" # Only to ensure MTU is actually set
    fi

    # Set for DHCP address first
    xe pif-reconfigure-ip uuid="$pif" mode=dhcp

    # Convert DHCP to static address
    ipv4_prefix=$( ip addr list dev "$dev" | awk '/inet /{print $2}' )
    [[ $ipv4_prefix ]] || continue

    # Determine gateway (next-hop) for this interface
    temp_file=$(mktemp)
    ADDRESS="${ipv4_prefix%%/*}"
    ipcalc -4 -b -m -n -p  "$ipv4_prefix" > "$temp_file"; source "$temp_file"
    gateways=( $(ip -f inet route list dev "$dev" exact 0.0.0.0/0.0.0.0 | awk '{print $3}') )

    for ip in "${gateways[@]}"; do
      net=$(get_network "$ip" "$NETMASK")
      if [[ $net = $NETWORK ]]; then GATEWAY="$ip"; break; fi
    done

    # Set address for interface
    xe pif-reconfigure-ip uuid="$pif"       \
      DNS="$dns_server_list"                \
      mode=static                           \
      IP="$ADDRESS"                         \
      netmask="$NETMASK"                    \
      gateway="$GATEWAY"
    
  done

done

