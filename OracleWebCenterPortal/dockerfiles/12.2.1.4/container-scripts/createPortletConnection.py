#!/usr/bin/python
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
import sys

#============================================================
#Connect To AdminServer and create Portlet Server Connection
#============================================================
adminHost     = os.environ.get("ADMIN_SERVER_CONTAINER_NAME")
adminPort     = os.environ.get("ADMIN_PORT")
adminName     = os.environ.get("ADMIN_USERNAME")
adminPassword = os.environ.get("ADMIN_PASSWORD")
url = adminHost + ":" + adminPort
producerHost = sys.argv[1]
producerPort = os.environ.get("MANAGED_SERVER_PORTLET_PORT")
connect(adminName, adminPassword, url)
try:
    registerOOTBProducers(producerHost,producerPort ,'webcenter')
    if  webcenterErrorOccurred():
        print "Error while registering OOTB Producers"
    print 'OOTB Producers Config ending at '
except Exception, ex:
    print ex.getMessage()
    print "Exception in Out-of-the-box Producer Configuration, exiting"