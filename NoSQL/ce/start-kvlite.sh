#!/bin/bash
#
# Copyright (c) 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

+set -ex

KVHOST=$HOSTNAME
_KV_HARANGE=`echo $KV_HARANGE | sed 's/\-/\,/g' `
_KV_SERVICERANGE=`echo $KV_SERVICERANGE | sed 's/\-/\,/g' `
java -jar lib/kvstore.jar kvlite -secure-config disable -root /kvroot -host $KVHOST -port $KV_PORT -admin-web-port $KV_ADMIN_PORT -harange $_KV_HARANGE -servicerange $_KV_SERVICERANGE &
java -jar lib/httpproxy.jar -helperHosts $KVHOST:$KV_PORT -storeName kvstore -httpPort $KV_PROXY_PORT -verbose true
