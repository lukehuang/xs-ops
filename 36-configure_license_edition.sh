#!/bin/bash

set -x -v
set -u
set +e  # This task must not fail given we might not always 
        # have licenses for new releases. We try anyway.

# Configuring host licenses
xe host-apply-edition                                   \
  'license-server-address'="${license_server:-xslicsrv.autostack.local}" \
  'edition'="${license_edition:-platinum}"              \
  'license-server-port'="${license_server_port:-27000}" \
  
# Tests
xe host-license-view
