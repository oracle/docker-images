#!/bin/bash
#
CONFIG_JVM_ARGS="${CONFIG_JVM_ARGS} -Dweblogic.security.SSL.ignoreHostnameVerification=true"
WLST="wlst.sh -skipWLSModuleScanning"
$WLST /u01/oracle/add-machine.py
