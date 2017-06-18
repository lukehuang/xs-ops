#!/bin/bash

# Reduce time to on reverse lookups
sed -i 's/.*UseDNS\ \+yes/UseDNS no/i' /etc/ssh/sshd_config

service sshd restart
