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
domainhome = os.environ.get('DOMAIN_HOME', '/u01/oracle/user_projects/domains/base_domain')
admin_name = os.environ.get('ADMIN_NAME', 'AdminServer')
appname    = os.environ.get('APP_NAME', 'sample')
apppkg     = os.environ.get('APP_PKG_FILE', 'sample.war')
appdir     = os.environ.get('APP_PKG_LOCATION', '/u01/oracle')
cluster_name = os.environ.get("CLUSTER_NAME", "DockerCluster")

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
assign('AppDeployment', appname, 'Target', admin_name)
assign('AppDeployment', appname, 'Target', cluster_name)

# Update Domain, Close It, Exit
# ==========================
updateDomain()
closeDomain()
exit()
