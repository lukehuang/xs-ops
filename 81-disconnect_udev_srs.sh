#!/bin/bash

set -eu

uuids=( $(xe sr-list type=udev params=uuid --minimal | sed 's/,/\n/g') )

( set +u
  for uuid in "${uuids[@]}"; do
    echo "PATH: $PATH"
    which autostack.xenserver.sr.disconnect || true
    autostack.xenserver.sr.disconnect -u "$uuid"
  done
)

