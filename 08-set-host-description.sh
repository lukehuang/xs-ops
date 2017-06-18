#!/bin/bash

set -eu

xe host-param-set                     \
  uuid="$this_host_uuid"              \
  name-description="$host_description"
