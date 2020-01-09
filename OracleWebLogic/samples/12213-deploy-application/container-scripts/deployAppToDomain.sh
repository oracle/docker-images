#!/bin/bash
#
#Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.

#Define DOMAIN_HOME
echo "Domain Home is: " $DOMAIN_HOME

# Deploy Application
wlst.sh -skipWLSModuleScanning /u01/oracle/app-deploy.py
