#!/bin/bash

# Workaround for when XS doesn't seem to have created the
# ~/.ssh directory in time for the 
# fix_ssh_permissions script to be run.

root_homedir=$(getent passwd root | awk -F: '{print $6}')
root_homedir="${root_homedir:-/root}"

if [[ ! -e $root_homedir ]]; then
  mkdir -pv "$root_homedir"
fi
chmod -Rv 2755 "$root_homedir"

for ssh_dir in /etc/ssh "$root_homedir/.ssh/"; do
  if [[ ! -e "$ssh_dir" ]]; then
    mkdir -pv "$ssh_dir"
  fi
  chmod -Rv 0700 "$ssh_dir"
done


