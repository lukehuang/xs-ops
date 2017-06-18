#!/bin/bash

# set -vex

# Deleting network 'AutoBVT2'
network_uuid="$(xe network-list name-label="AutoBVT2" params=uuid --minimal)"
if [[ $network_uuid ]]; then
  xe network-destroy uuid="$network_uuid"
fi

