#!/usr/bin/python
# Copyright (c)  2020, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
import sys

#============================================================
#Connect To AdminServer and create Search Connection
#============================================================

adminHost     = os.environ.get("ADMIN_SERVER_CONTAINER_NAME")
adminPort     = os.environ.get("ADMIN_PORT")
adminName     = os.environ.get("ADMIN_USERNAME")
adminPassword = os.environ.get("ADMIN_PASSWORD")

searchConnName = os.environ.get("SEARCH_CONNECTION_NAME")
searchUserName = os.environ.get("SEARCH_APP_USERNAME")
searchUserPwd  = os.environ.get("SEARCH_APP_USER_PASSWORD")
indexAliasName = os.environ.get("SEARCH_INDEX_ALIAS_NAME")
loadBalancerIP = os.environ.get("LOAD_BALANCER_IP")
nodeName = os.environ.get("NODE_NAME")


esHost = sys.argv[1]
searchUrl = 'http://' + esHost + ':9200'

print('')
print('Creating Search Connection');
print('=====================================');
print('Parameters:');
print('Connection Name: ' + searchConnName);
print('Search URL: ' + searchUrl);
print('Search App User Name: ' + searchUserName);
print('Search Index Alias Name: ' + indexAliasName);
print('')

url = adminHost + ":" + adminPort
connect(adminName, adminPassword, url)

if (nodeName == 'es-statefulset-0'):
 searchUrl = 'http://' + loadBalancerIP + ':9200'
 print('Search URL: ' + searchUrl);
 createSearchConnection(appName='webcenter', name=searchConnName, url=searchUrl, indexAliasName=indexAliasName, appUser=searchUserName, appPassword=searchUserPwd, server='wcpserver1')
 listSearchConnections(appName='webcenter', verbose=true, server='wcpserver1')

else:
  createSearchConnection(appName='webcenter', name=searchConnName, url=searchUrl, indexAliasName=indexAliasName, appUser=searchUserName, appPassword=searchUserPwd)
  listSearchConnections(appName='webcenter', verbose=true)
 
disconnect()
exit()
