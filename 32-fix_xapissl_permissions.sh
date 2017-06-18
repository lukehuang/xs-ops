#!/bin/bash

set -e -v -x

# Fix XAPI SSL Permissions
chown -v root:root  /etc/xensource/xapi-ssl.{pem,conf}
chmod -v 400        /etc/xensource/xapi-ssl.{pem,conf}
service xapissl restart

sleep 1

# Test XAPI Working
curl -kv "https://$(hostname -f)/"

