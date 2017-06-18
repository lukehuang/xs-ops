#!/bin/bash

# convert_local_sr_to_lvm_type
#   Addresses cloudstack requirements to ensure local storage is of type LVM.
#   Derived from recommendation on
#   http://buildacloud.org/forum/installation/8408-cloudstack-with-xenserver-and-local-storage-troubles.html

set -eu

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

sr_uuids=( $(xe sr-list type=ext params=uuid --minimal | sed 's/,//g') )

for uuid in ${sr_uuids[@]}; do
  echo "Converting SR uuid=$uuid"
  xe sr-list uuid="$uuid" >&2
  autostack.xenserver.sr.ext.convert_to_lvm -u "$uuid" -d
done

