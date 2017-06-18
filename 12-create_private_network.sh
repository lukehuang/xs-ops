#!/bin/bash

# set -vex

# Creating network 'AutoBVT2'
network_uuid="$(xe network-list name-label="AutoBVT2" params=uuid --minimal)"
[[ -z $network_uuid ]] && xe network-create \
    name-label='AutoBVT2' \
    'MTU'='1500' \
    'name-description'='Network for inter-VM Comms.'


