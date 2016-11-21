#!/bin/sh

exec /usr/bin/confd \
    -backend stackengine \
    -node $KV_IP:$KV_PORT \
    -scheme http \
    -auth-token $OCCS_API_TOKEN \
    -interval 5
