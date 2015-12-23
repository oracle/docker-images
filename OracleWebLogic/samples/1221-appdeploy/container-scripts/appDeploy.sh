#!/bin/bash
CONFIG_JVM_ARGS="${CONFIG_JVM_ARGS} -Dweblogic.security.SSL.ignoreHostnameVerification=true"
WLST="wlst.sh -skipWLSModuleScanning"

# Deploy the application 
$WLST /u01/oracle/app-deploy.py
