#Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
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

clusterNoLeasing='cluster-no-leasing.json'
clusterWithLeasing='cluster-leasing.json'
defaultDSModule='ds1-jdbc.xml'

def createDomainWithLeasing():
    base.waitAdmin()
    base.cpJDBCResource(defaultDSModule);
    base.createAll(clusterWithLeasing)

def createDomainNoLeasing():
    base.waitAdmin()
    base.createAll(clusterNoLeasing)

def createRes(jsonFile):
    base.createAll(jsonFile)

print 'url:', base.prefix
start=time()
option=sys.argv[1]
if(option == 'createDomainNoLeasing'):
    createDomainNoLeasing()
elif(option == 'createDomainWithLeasing'):
    createDomainWithLeasing();
elif(option == 'createRes'):
    createRes(sys.argv[2])

end=time()
print option, "spent", (end-start), "seconds"
