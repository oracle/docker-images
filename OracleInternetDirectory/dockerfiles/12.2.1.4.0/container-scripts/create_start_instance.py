#!/usr/bin/python 
# Copyright (c) 2021, Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Author: Pratyush Dash
#
import os, sys
hostname       = socket.gethostname()
domain_name  = os.environ.get("DOMAIN_NAME", "oid_domain")
oracle_home = os.environ.get("ORACLE_HOME", "/u01/oracle/")
weblogic_home = '/u01/oracle/wlserver'

domain_name      = os.environ.get("DOMAIN_NAME")
admin_name       = os.environ.get("ADMIN_NAME", "AdminServer")
admin_port       = int(os.environ.get("ADMIN_LISTEN_PORT", "7001"))
domain_path      = os.environ.get("DOMAIN_HOME")
admin_host       = os.environ.get('ADMIN_LISTEN_HOST', 'AdminServer')

# Node Manager Vars
nmname         = os.environ.get('NM_NAME', 'Machine-' + hostname)

i = 1
while i < len(sys.argv):
    if sys.argv[i] == '-user':
        user = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-password':
        password = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-instance_Name':
        instanceName= sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-machine_Name':
        machineName= sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-admin_Port':
        admin_port= sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-admin_Hostname':
        admin_host= sys.argv[i + 1]
        i += 2
    else:
        print 'Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i])
        sys.exit(1)
try:
    WL_HOME = weblogic_home
    DOMAIN_HOME = domain_path
    ORACLE_HOME = oracle_home
    if DOMAIN_HOME is None:
        sys.exit("Error: Please set the environment variable DOMAIN_HOME")
    if WL_HOME is None:
        sys.exit("Error: Please set the environment variable WL_HOME")
    if ORACLE_HOME is None:
        sys.exit("Error: Please set the environment variable ORACLE_HOME")
except (KeyError), why:
    sys.exit("Error: Missing Environment Variables " + str(why))
try:
    connect(user, password, url='t3://' + admin_host + ':' + admin_port)
    oid_createInstance(instanceName=instanceName,machine=machineName,port='3060',host=machineName)
    start(instanceName)
    exit()
except:
    print 'Unable to create OID instance...'
    exit()
