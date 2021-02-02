#!/usr/bin/python
#
# # Copyright (c) 2020, 2021 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Author: Kaushik C
#
#
# Updates the listen address for managed server with the IP address of the host.
# ==============================================
#
import sys

#
# Assigning values to variables
# =============================
domain_home = os.environ.get("DOMAIN_HOME", "/u01/oracle/user_projects/domains/base_domain")

#
# Reading db details and schema prefix passed from parent script
# ==============================================================
manserver_host=sys.argv[1]
server=sys.argv[2]
exthost=sys.argv[3]

#
# Setting domain path
# ===================
domain_path  = domain_home

#
# Read domain for updates
# =======================
readDomain(domain_path)

#
# Set listen address
# ==================
cd('/')
cd('/Server/'+server)
cmo.setListenAddress(manserver_host)
cmo.setExternalDNSName(exthost)

# Creating domain
# ===============
updateDomain()
closeDomain()
exit()
