#!/bin/bash

set -eu
set -xv

# Create and Configure Storage Repositories
source host.conf

function parse_cifs_url {
  local url="$1"
  local delim="$2"
  local str="${url#cifs://}"
  local hostname="${str%%/*}"
  local path="/${str#*/}"
  if [[ -z $hostname || -z $path ]]; then
    echo "Error parsing cifs:// url '$url'"
    exit 3
  fi
  echo "${hostname%/}$delim${path%/}"
}


for sr in "${sr_iso_sr_list[@]-}"; do

  [[ $sr ]] || continue

  sr_name_label="${sr%%:*}"
  sr_url="${sr#*:}"
  echo ""
  echo "sr_definition : $sr"
  echo "sr_name_label : $sr_name_label"
  echo "sr_url        : $sr_url"

  if [[ $sr_url = cifs://* ]]; then
    cifs_parts=($( parse_cifs_url "$sr_url" ' '))
    cifs_server="${cifs_parts[0]}"
    cifs_path="${cifs_parts[1]}"
    cifs_options=""
    for domain_def in "${sr_iso_sr_cifs_options[@]}"; do
      domain="${domain_def%%:*}"
      options="${domain_def#*:}"
      if [[ $cifs_server = *$domain ]]; then
        cifs_options="$options"
        break
      fi
    done
    if [[ -n $cifs_options ]]; then
      autostack.xenserver.sr.cifs_iso.create -u "$sr_url" -s "$sr_name_label" -o "$cifs_options" -v
    else
      autostack.xenserver.sr.cifs_iso.create -u "$sr_url" -s "$sr_name_label" -v
    fi
  elif [[ $sr_url = nfs://* ]]; then
    echo "Mounting NFS ISO SRs currently not implemented."
    exit 3
  else
    echo "No ISO SR processor for '$sr_url' implemented"
    exit 3
  fi

done


for sr in "${sr_vm_sr_list[@]-}"; do

  [[ $sr ]] || continue

  sr_name_label="${sr%%:*}"
  sr_url="${sr#*:}"
  echo ""
  echo "sr_definition : $sr"
  echo "sr_name_label : $sr_name_label"
  echo "sr_url        : $sr_url"

  if [[ $sr_url = nfs://* ]]; then
    autostack.xenserver.sr.nfs_vm.create -u "$sr_url" -s "$sr_name_label"
  else
    echo "No VM SR processor for $sr_url implemented"
    exit 3
  fi

done


if [[ $sr_vm_sr_default ]]; then
  pool_uuid=$(xe pool-list params=uuid --minimal)
  xe sr-list name-label="$sr_vm_sr_default" params=uuid --minimal |
    sed -r 's/,/\n/g' |
    while read sr_uuid _; do
      xe pool-param-set uuid="$pool_uuid" default-SR="$sr_uuid"
    done
fi
