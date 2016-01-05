#!/bin/bash
#
# Copyright (c) 2014-2015 Oracle and/or its affiliates. All rights reserved.
#
CONFIG_JVM_ARGS="${CONFIG_JVM_ARGS} -Dweblogic.security.SSL.ignoreHostnameVerification=true"
WLST="wlst.sh -skipWLSModuleScanning"

# Start Node Manager
. /u01/oracle/weblogic/oracle_common/common/bin/setNMProps.sh
nohup startNodeManager.sh > log.nm &
sleep 5

# Add a Machine to the AdminServer
$WLST /u01/oracle/add-machine.py

# print log
tail -f log.nm
