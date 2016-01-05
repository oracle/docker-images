# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
#
# WLST Offline for deploying an application under APP_NAME packaged in APP_PKG_FILE located in APP_PKG_LOCATION
# It will read the domain under DOMAIN_HOME by default
#
# author: Bruno Borges <bruno.borges@oracle.com>
# since: December, 2015
#
import os

# Deployment Information 
domainhome = os.environ.get('DOMAIN_HOME', '/u01/oracle/weblogic/user_projects/domains/base_domain')
appname    = os.environ.get('APP_NAME', 'sample')
apppkg     = os.environ.get('APP_PKG_FILE', 'sample.war')
appdir     = os.environ.get('APP_PKG_LOCATION', '/u01/oracle')

# Read Domain in Offline Mode
# ===========================
readDomain(domainhome)

# Create Application
# ==================
cd('/')
app = create(appname, 'AppDeployment')
app.setSourcePath(appdir + '/' + apppkg)
app.setStagingMode('nostage')
 
# Assign application to AdminServer
# =================================
assign('AppDeployment', appname, 'Target', 'AdminServer')

# Update Domain, Close It, Exit
# ==========================
updateDomain()
closeDomain()
exit()
