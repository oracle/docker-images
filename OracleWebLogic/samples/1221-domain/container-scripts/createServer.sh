#!/bin/bash
#
# Copyright (c) 2014-2015 Oracle and/or its affiliates. All rights reserved.
#
CONFIG_JVM_ARGS="${CONFIG_JVM_ARGS} -Dweblogic.security.SSL.ignoreHostnameVerification=true"
WLST="wlst.sh -skipWLSModuleScanning"

# Start Node Manager
nohup startNodeManager.sh > log.nm &
sleep $DELAY_NM_REGISTRATION

# Add a Machine to the AdminServer
$WLST /u01/oracle/add-machine.py

# Wait and add a new Managed Server
$WLST /u01/oracle/add-server.py

# print log
tail -f log.nm
