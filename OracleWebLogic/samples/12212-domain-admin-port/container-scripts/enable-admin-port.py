# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
#
# author: Amy Moon <amy.roh@oracle.com>
# since: May, 2017
#
import os

# Deployment Information 
domainhome = os.environ.get('DOMAIN_HOME', '/u01/oracle/user_projects/domains/base_domain')
administration_port = int(os.environ.get("ADMINISTRATION_PORT", "9002"))

# Read Domain in Offline Mode
# ===========================
readDomain(domainhome)

# Enable Administration Port
# ===========================
cd('/')
set('AdministrationPortEnabled', 'true')
set('AdministrationPort', administration_port)

# Enable two ways SSL for this AdminServer
# ===========================
cd('/Servers/AdminServer')
ssl=create('AdminServer','SSL')
ssl.setEnabled(true)
ssl.setHostnameVerifier(None)
ssl.setHostnameVerificationIgnored(true)
ssl.setTwoWaySSLEnabled(true)

# Update Domain, Close It, Exit
# ==========================
updateDomain()
closeDomain()
exit()
