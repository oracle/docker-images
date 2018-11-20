#Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# WebLogic on Docker Default Domain
#
# Domain, as defined in DOMAIN_NAME, will be created in this script. Name defaults to 'base_domain'.
#
# Since : July, 2017
# Author: monica.riccelli@oracle.com
# ==============================================
#Env Vars
# ------------------------------
domain_name      = os.environ.get("DOMAIN_NAME")
admin_name       = os.environ.get("ADMIN_NAME", "AdminServer")
admin_port       = int(os.environ.get("ADMIN_PORT", "7001"))
admin_pass       = "ADMIN_PASSWORD"
cluster_name     = os.environ.get("CLUSTER_NAME", "DockerCluster")
domain_path      = os.environ.get("DOMAIN_HOME")
production_mode  = os.environ.get("PRODUCTION_MODE", "prod")

print('domain_name     : [%s]' % domain_name);
print('admin name      : [%s]' % admin_name);
print('admin_port      : [%s]' % admin_port);
print('cluster_name    : [%s]' % cluster_name);
print('domain_path     : [%s]' % domain_path);
print('production_mode : [%s]' % production_mode);

# Open default domain template
# ======================
readTemplate("/u01/oracle/wlserver/common/templates/wls/wls.jar")

set('Name', domain_name)
setOption('DomainName', domain_name)

# Disable Admin Console
# --------------------
# cmo.setConsoleEnabled(false)

# Configure the Administration Server and SSL port.
# =========================================================
cd('/Servers/AdminServer')
set('Name', admin_name)
set('ListenAddress', '')
set('ListenPort', admin_port)

# Define the user password for weblogic
# =====================================
cd('/Security/%s/User/weblogic' % domain_name)
cmo.setPassword(admin_pass)

# Write the domain and close the domain template
# ==============================================
setOption('OverwriteDomain', 'true')
setOption('ServerStartMode',production_mode)

cd('/NMProperties')
set('ListenAddress','')
set('ListenPort',5556)
set('CrashRecoveryEnabled', 'true')
set('NativeVersionEnabled', 'true')
set('StartScriptEnabled', 'false')
set('SecureListener', 'false')
set('LogLevel', 'FINEST')
set('DomainsDirRemoteSharingEnabled','true')

# Set the Node Manager user name and password (domain name will change after writeDomain)
cd('/SecurityConfiguration/base_domain')
set('NodeManagerUsername', 'weblogic')
set('NodeManagerPasswordEncrypted', admin_pass)

# Define a WebLogic Cluster
# =========================
cd('/')
create(cluster_name, 'Cluster')

cd('/Clusters/%s' % cluster_name)
cmo.setClusterMessagingMode('unicast')

# Write Domain
# ============
writeDomain(domain_path)
closeTemplate()

# Exit WLST
# =========
exit()
