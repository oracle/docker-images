#!/usr/bin/python
# Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Script to make simple EDQ 12.2.1 domain
# ---------------------------------------
execfile("/u01/oracle/container-scripts/edq.py")
i = 1
while i < len(sys.argv):
    if sys.argv[i] == '-oh':
        wls = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-jh':
        javaHome = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-parent':
        domainParentDir = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-name':
        domain = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-user':
        domainUser = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-password':
        weblogicpw  = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-dbhost':
        dbhost = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-dbport':
        dbport = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-dbservice':
        dbservice = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-rcuPrefix':
        dbprefix = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-rcuSchemaPwd':
        rcuSchemaPassword = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-adminPort':
        adminport = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-edqPort':
        edqport = sys.argv[i + 1]
        i += 2
    else:
        print 'Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i])
        usage()
        sys.exit(1)


nmport    = 5556
heap      = 4096
servers   = 1


# Make the domain

edqdomain(domain, wls, dbhost, dbport, dbservice, dbprefix, rcuSchemaPassword, weblogicpw, adminport=adminport, edqport=edqport, nmport=nmport, edqheap=heap, servers=servers)
