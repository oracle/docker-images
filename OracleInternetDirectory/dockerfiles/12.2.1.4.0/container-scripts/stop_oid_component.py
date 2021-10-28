#!/usr/bin/python
#
# Copyright (c) 2021, Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Author: Pratyush Dash
#
import os, sys, re
domain_name  = os.environ.get("DOMAIN_NAME", "oid_domain")
oracle_home = os.environ.get("ORACLE_HOME", "/u01/oracle/")
weblogic_home = '/u01/oracle/wlserver'

# Node Manager Vars

i = 1
while i < len(sys.argv):
    if sys.argv[i] == '-username':
        user = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-adminpassword':
        password = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-instance_Name':
        instanceName= sys.argv[i + 1]
        i += 2
    else:
        print 'Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i])
        sys.exit(1)
try:
    nmConnect(domainName=domain_name,username=user,password=password,nmType='ssl')
    nmServerStatus(serverName=instanceName,serverType='OID')
    nmKill(serverName=instanceName,serverType='OID')
    exit()
except:
    print 'Unable to kill '+instanceName
    exit()
