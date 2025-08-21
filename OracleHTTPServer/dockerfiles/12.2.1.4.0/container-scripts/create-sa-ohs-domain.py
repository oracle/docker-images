#!/usr/bin/python
#
# Copyright (c) 2024 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Create OHS Domain and OHS System component
#
# OHS Domain 'ohsDomain' (or anything defined under DOMAIN_NAME) to be created inside the Docker image for OHS
# OHS System Component "ohs1" (Or anything defined under OHS_COMPONENT_NAME)to be created inside the Docker image for OHS
#
# Author: hemastuti.baruah@oracle.com
# ==============================================
import os, sys
#admin_port   = (os.environ.get("ADMIN_PORT", "7001"))
ohs_http_port   = (os.environ.get("OHS_LISTEN_PORT", "7777"))
ohs_ssl_port   = (os.environ.get("OHS_SSL_PORT", "3333"))
ohs_comp_name   = os.environ.get("OHS_COMPONENT_NAME", "ohs1")
domain_name  = os.environ.get("DOMAIN_NAME", "ohsDomain")
domain_path  = os.environ.get("DOMAIN_HOME", "/u01/oracle/user_projects/domains/ohsDomain")

print('domain_name : [%s]' % domain_name);
print('domain_path : [%s]' % domain_path);
print('ohs_comp_name : [%s]' % ohs_comp_name);

# Select OHS standalone template
# ==============================================
setTopologyProfile('Compact')
selectTemplate('Oracle HTTP Server (Standalone)')
loadTemplates()
showTemplates()
# Create OHS System Component by the name ohs1, Configure OHS Listen Port and SSL Port
# ======================================================================
cd('/')
cd('SystemComponent/' + ohs_comp_name)
set('ComponentType','OHS')
cd('/')
cd('OHS/' + ohs_comp_name)
set('ListenAddress','')
set('ListenPort', ohs_http_port)
set('SSLListenPort', ohs_ssl_port)
# Set NodeManager user name and password
# ======================================================================
cd('/')
create('sc', 'SecurityConfiguration')
cd('SecurityConfiguration/sc')
set('NodeManagerUsername', username)
set('NodeManagerPasswordEncrypted', password)
#set('NodeManagerUsername','weblogic')
#set('NodeManagerPasswordEncrypted','welcome1')
setOption('NodeManagerType','PerDomainNodeManager')
setOption('OverwriteDomain', 'true')
#Write Domain, close template and exit
# ======================================================================
#writeDomain(r'/u01/oracle/user_projects/domains/ohsDomain')
writeDomain(domain_path)
dumpStack()
closeTemplate()
exit()
