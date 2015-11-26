#!/bin/bash
CONFIG_JVM_ARGS="${CONFIG_JVM_ARGS} -Dweblogic.security.SSL.ignoreHostnameVerification=true"
WLST="wlst.sh -skipWLSModuleScanning"

# Start Node Manager
. /u01/oracle/occas/oracle_common/common/bin/setNMProps.sh
nohup startNodeManager.sh > log.nm &
sleep 5

# Add a Machine to the AdminServer
$WLST /u01/oracle/add-machine.py

# print log
tail -f log.nm
