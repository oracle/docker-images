# Copyright (c) 2021, 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
#

KVHOST=`hostname`
java -jar lib/kvstore.jar kvlite  -secure-config disable -root /kvroot &
java -jar lib/httpproxy.jar -helperHosts $KVHOST:5000 -storeName kvstore -httpPort $KV_PROXY_PORT -verbose true
