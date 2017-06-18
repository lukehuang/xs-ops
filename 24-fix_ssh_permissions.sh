#!/bin/bash

# set -eu
set -vx

# source ssh.utils.sh

#  Fix SSH Permissions in case we rsync from a
#  source that doesn't preserve these permissions e.g. CIFS

chown  -v root:root /root
chown -Rv root:root /root/.ssh
chmod -Rv 700       /root/.ssh

chown -Rv root:root /etc/ssh*
chmod -Rv 700       /etc/ssh*

if [[ -e /etc/rc.d/init.d/sshd ]]; then
  # Just in case /etc/init.d/ is missing
  /etc/rc.d/init.d/sshd restart
else
  service sshd restart
fi

# Tests
service sshd status
netstat -planto | grep -i ":22.*LISTEN"
fuser -v -n tcp 22 
fuser -v $(type -P sshd)
pidof sshd | xargs -i ps eu -p {} 

# Test that sshd is actually serving requests.
ssh-keyscan -t rsa -H "$(hostname -s)"
ssh-keyscan -t rsa -H "$(hostname -f)"
# On IP Addresses known for hostname
getent ahosts "$(hostname -f)"    |
  awk '$2 ~ /STREAM/{ print $1 }' |
  xargs -i ssh-keyscan -t rsa -H {} 

alarm 3 ssh -oConnectTimeout=5 "$(hostname -f)" "hostname" || true
