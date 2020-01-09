# Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#

# WLST Offline for deploying an application under APP_NAME packaged in APP_PKG_FILE located in APP_PKG_LOCATION
# It will read the domain under DOMAIN_HOME by default
#
# author: Monica Riccelli <monica.riccelli@oracle.com>
#
import os

# Deployment Information
domainhome = os.environ.get('DOMAIN_HOME', '/u01/oracle/user_projects/domains/base_domain')
admin_name = os.environ.get('ADMIN_NAME', 'AdminServer')
appname    = os.environ.get('APP_NAME', 'simple-app')
appfile    = os.environ.get('APP_FILE', 'simple-app.war')
appdir     = os.environ.get('DOMAIN_HOME')
cluster_name = os.environ.get("CLUSTER_NAME", "DockerCluster")

print('Domain Home      : [%s]' % domainhome);
print('Admin Name       : [%s]' % admin_name);
print('Cluster Name     : [%s]' % cluster_name);
print('Application Name : [%s]' % appname);
print('appfile          : [%s]' % appfile);
print('appdir           : [%s]' % appdir);
# Read Domain in Offline Mode
# ===========================
readDomain(domainhome)

# Create Application
# ==================
cd('/')
app = create(appname, 'AppDeployment')
app.setSourcePath(appdir + '/' + appfile)
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
