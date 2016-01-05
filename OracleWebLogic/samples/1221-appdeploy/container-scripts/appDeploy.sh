#!/bin/bash
# 
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
# 
CONFIG_JVM_ARGS="${CONFIG_JVM_ARGS} -Dweblogic.security.SSL.ignoreHostnameVerification=true"
WLST="wlst.sh -skipWLSModuleScanning"

# Deploy the application 
$WLST /u01/oracle/app-deploy.py
