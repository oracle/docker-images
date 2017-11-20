#Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Author Lily He

import requests
from requests.auth import HTTPBasicAuth 
import json
import shutil
import sys
import os
from time import time
from time import sleep
from collections import OrderedDict
import base

clusterData='cluster.json'
defaultDSModule='ds1-jdbc.xml'
defaultDSJson='ds.json'
defaultJMSModule='mymodule-jms.xml'
defaultJMSJson='jmsres.json'

def createAll():
    createDomain()
    createDS(defaultDSModule, defaultDSJson)
    createJMS(defaultJMSModule, defaultJMSJSON)
 
def createDomain():
    base.waitAdmin()
    base.createAll(clusterData)

def createDS(DSModule, DSJson):
    base.cpJDBCResource(DSModule)
    base.createAll(DSJson)

def createJMS(JMSModule, JMSJson):
    base.cpJMSResource(JMSModule)
    base.createAll(JMSJson)

print 'url:', base.prefix 
start=time()
option=sys.argv[1]
if(option == 'createDomain'):
    createDomain()
elif(option == 'createJMS'):
    createJMS(sys.argv[2], sys.argv[3])
elif(option == 'createDS'):
    createDS(sys.argv[2], sys.argv[3])
elif(option == 'createAll'):
    createAll()

end=time()
print option, "spent", (end-start), "seconds"
