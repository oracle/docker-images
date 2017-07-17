#!/usr/bin/python
#
# Author:swati.mukundan@oracle.com
#
# Copyright (c) 2016-2017 Oracle and/or its affiliates. All rights reserved.
#
# SOA on Docker Default Domain
#
# Updates the listen address for managed server with the IP address of the host.
#
# Since : April, 2016
# Author: swati.mukundan@oracle.com
# ==============================================
import sys
#
# Assigning values to variables
# ==================================
domain_name  = os.environ.get("DOMAIN_NAME", "base_domain")
domain_root = os.environ.get("DOMAIN_ROOT", "/u01/oracle/user_projects/domains")

#
# Reading db details and schema prefix passed from parent script
# ==============================================================
vol_name=sys.argv[1]
manserver_host=sys.argv[2]
server=sys.argv[3]
#
# Setting domain path
# ===================
domain_path  = domain_root + '/' + domain_name
#
#
#
# Read domain for updates
# =======================
readDomain(domain_path)
#
#
# Set listen address
# ==================
cd('/')
cd('/Server/'+server)
cmo.setListenAddress(manserver_host)

# Creating domain
# ==============================
updateDomain()
closeDomain()
exit()
