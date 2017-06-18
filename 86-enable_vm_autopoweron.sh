#!/bin/bash

source /etc/xensource-inventory

pool_uuid=$(xe pool-list master="$INSTALLATION_UUID" params=uuid --minimal)

xe pool-param-set uuid="$pool_uuid" other-config:auto_poweron=true

