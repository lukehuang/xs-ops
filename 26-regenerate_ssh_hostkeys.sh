#!/bin/bash

# Generate the SSH key pairs if they don't exit

set -eu
set -xv

# Add fix in to get tilde (~) expansion working early
# Even $HOME is not guarateed to be present/populated
# So we try to divine the home dir and set $HOME
IFS=: read -a rootpasswd < <( getent passwd root )
HOME="${rootpasswd[5]}"
HOME="${HOME:-/root}" # Failsafe

[[ -d $HOME ]] || mkdir -pv "$HOME"

for key_type in rsa dsa; do
  if [[ ! -e "$HOME"/.ssh/id_"${key_type}" ]]; then
    ssh-keygen  -t "$key_type"                    \
                -C "SSH $key_type for $HOSTNAME"  \
                -N ""                             \
                -f "$HOME"/.ssh/id_"${key_type}"
  fi
done
