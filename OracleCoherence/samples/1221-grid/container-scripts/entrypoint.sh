#!/bin/sh
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
#
# author: Bruno Borges <bruno.borges@oracle.com>
#
usage() {
cat << EOF
Oracle Coherence on Docker
--------------------------
Usage: docker run -ti 1221-grid [ -h | server | console ]

 server : will start a Cache Server 
 console: will start a Coherence Console
 -h     : shows this help message

LICENSE CDDL 1.0 + GPL 2.0

Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.

EOF
exit 0
}

if [ "$1" = "" ] || [ "$1" = "-h" ]; then
  usage
fi

if [ "$1" = "server" ]; then
  $JAVA_HOME/bin/java -cp /config:$ORACLE_HOME/coherence/lib/coherence.jar \
    -Dtangosol.coherence.cluster=$CLUSTER_NAME $COHERENCE_OPTIONS \
    com.tangosol.net.DefaultCacheServer
elif [ "$1" = "console" ]; then
  $JAVA_HOME/bin/java -cp /config:$ORACLE_HOME/coherence/lib/coherence.jar \
    -Dtangosol.coherence.distributed.localstorage=false \
    -Dtangosol.coherence.cluster=$CLUSTER_NAME $COHERENCE_OPTIONS \
    com.tangosol.net.CacheFactory
else
  echo "Invalid option. See usage with -h"
  exit 1
fi
