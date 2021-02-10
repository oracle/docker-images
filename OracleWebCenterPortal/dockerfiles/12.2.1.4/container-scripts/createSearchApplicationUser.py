#!/usr/bin/python
# Copyright (c)  2020, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
import sys

#============================================================
#Connect To AdminServer and create search application user
#============================================================

adminHost     = os.environ.get("ADMIN_SERVER_CONTAINER_NAME")
domainName    = os.environ.get("DOMAIN_NAME")
adminPort     = os.environ.get("ADMIN_PORT")
adminName     = os.environ.get("ADMIN_USERNAME")
adminPassword = os.environ.get("ADMIN_PASSWORD")

searchUserName = os.environ.get("SEARCH_APP_USERNAME") 
searchUserPwd  = os.environ.get("SEARCH_APP_USER_PASSWORD")
searchUserDesc = "Search application user"

url = adminHost + ":" + adminPort
connect(adminName, adminPassword, url)
serverConfig()
cd('/SecurityConfiguration/' + domainName + '/Realms/myrealm/AuthenticationProviders/DefaultAuthenticator')
if(cmo.userExists(searchUserName)):
  print 'INFO: Not creating the user. User ' + searchUserName + ' already exists.'
else:
  cmo.createUser(searchUserName, searchUserPwd, searchUserDesc)
  print 'INFO: Successfully created the user: ' + searchUserName
 
disconnect()
exit()

