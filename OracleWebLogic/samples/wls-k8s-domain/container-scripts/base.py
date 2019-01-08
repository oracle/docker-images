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
import os

adminPort=os.environ["ADMIN_PORT"]
prefix='http://localhost:' + adminPort + '/management/weblogic/latest/'
domainDir=os.environ["SAMPLE_DOMAIN_HOME"]
jmsFileName="mymodule-jms.xml"
jdbcFileName="ds1-jdbc.xml"

print (prefix, domainDir)

user = os.environ["WLUSER"]
pwd = os.environ["WLPASSWORD"]
auth = HTTPBasicAuth(user, pwd)
header1 = {'X-Requested-By': 'pythonclient','Accept':'application/json','Content-Type':'application/json'}
header2 = {'X-Requested-By': 'pythonclient','Accept':'application/json'}

def delete(tail):
    myResponse = requests.delete(prefix+tail, auth=auth, headers=header2, verify=True)
    result(myResponse, 'delete', 'false')

def get(tail):
    myResponse = requests.get(prefix+tail, auth=auth, headers=header2, verify=True)
    result(myResponse, 'get', 'false')
    return myResponse

def result(res, opt, fail):
    print (res.status_code)
    if(not res.content.isspace()):
        print (res.content)
    if(res.ok):
        print opt, 'succeed.'
    else:
        print opt, 'failed.'
        if(fail == 'true'):
            res.raise_for_status()

def waitAdmin():
    print("wait until admin started")
    tail='domainRuntime/serverRuntimes/'
    fail = True
    while(fail):
        sleep(2)
        try:
            res = requests.get(prefix+tail, auth=auth, headers=header2, verify=True)
            print res.status_code
            if(res.ok):
                fail=False
        except Exception:
            print "waiting admin started..."

def cpJMSResource(modulefile):
    print("cpJMSResource", modulefile)
    destdir=domainDir+'/config/jms/'
    try:
        os.makedirs(destdir)
    except OSError:
        if not os.path.isdir(destdir):
            raise
    destfile=destdir + jmsFileName
    shutil.copyfile(modulefile, destfile)
    print('copy jms resource finished.')

def cpJDBCResource(modulefile):
    print("cpJDBCResource", modulefile)
    destdir=domainDir+'/config/jdbc/'
    try:
        os.makedirs(destdir)
    except OSError:
        if not os.path.isdir(destdir):
            raise
    destfile=destdir + jdbcFileName
    shutil.copyfile(modulefile, destfile)
    print('copy jdbc resource finished. from', modulefile, 'to', destfile)

def createOne(name, tail, data):
    #print("create", name, tail, data)
    jData = json.dumps(data, ensure_ascii=False)
    print(jData)
    myResponse = requests.post(prefix+"edit/"+tail, auth=auth, headers=header1, data=jData, verify=True)
    result(myResponse, 'create ' + name, 'true')

def createAll(inputfile):
    jdata = json.loads(open(inputfile, 'r').read(), object_pairs_hook=OrderedDict)
    for tkey in jdata.keys():
        ss =jdata.get(tkey)
        for key in ss.keys():
            oneRes = ss.get(key)
            print(oneRes)
            createOne(key, oneRes['url'], oneRes['data'])
