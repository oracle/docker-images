# Copyright (c) 2014-2015 Oracle and/or its affiliates. All rights reserved.
#
# WebLogic on Docker Default Domain
#
# Domain, as defined in DOMAIN_NAME, will be created in this script. Name defaults to 'base_domain'.
#
# Since : October, 2014
# Author: bruno.borges@oracle.com
# ==============================================
domain_name  = os.environ.get("DOMAIN_NAME", "base_domain")
admin_port   = int(os.environ.get("ADMIN_PORT", "8001"))
admin_pass   = os.environ.get("ADMIN_PASSWORD")
cluster_name = os.environ.get("CLUSTER_NAME", "DockerCluster")
domain_path  = '/u01/oracle/user_projects/domains/' + domain_name

# Open default domain template
# ======================
readTemplate("/u01/oracle/wlserver/common/templates/wls/wls.jar")

# Disable Admin Console
# --------------------
# cmo.setConsoleEnabled(false)

# Configure the Administration Server and SSL port.
# =========================================================
cd('/Servers/AdminServer')
set('ListenAddress', '')
set('ListenPort', admin_port)

# Define the user password for weblogic
# =====================================
cd('/Security/' + domain_name + '/User/weblogic')
cmo.setPassword(admin_pass)

# Write the domain and close the domain template
# ==============================================
setOption('OverwriteDomain', 'true')
setOption('ServerStartMode','prod')

cd('/NMProperties')
set('ListenAddress','')
set('ListenPort',5556)
set('CrashRecoveryEnabled', 'true')
set('NativeVersionEnabled', 'true')
set('StartScriptEnabled', 'false')
set('SecureListener', 'false')
set('LogLevel', 'FINEST')

# Set the Node Manager user name and password
cd('/SecurityConfiguration/' + domain_name)
set('NodeManagerUsername', 'weblogic')
set('NodeManagerPasswordEncrypted', admin_pass)

# Define a WebLogic Cluster
# =========================
cd('/')
create(cluster_name, 'Cluster')

cd('/Clusters/' + cluster_name)
cmo.setClusterMessagingMode('unicast')

# Write Domain
# ============
writeDomain(domain_path)
closeTemplate()

# Enable JAX-RS 2.0 by default on this domain
# ===========================================
readDomain(domain_path)
addTemplate('/u01/oracle/jaxrs2-template.jar')
assign('Library', 'jax-rs#2.0@2.5.1', 'Target', cluster_name)
assign('Library', 'jax-rs#2.0@2.5.1', 'Target', 'AdminServer')
updateDomain()
closeDomain()

# Exit WLST
# =========
exit()
