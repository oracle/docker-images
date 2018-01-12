#!/usr/bin/python
#
# Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Description: This python script is used to register managed server with admin server in the domain.
#
# ==============================================
import sys
#
# Assigning values to variables, default if not setby user
# ==================================
domain_name = os.environ.get("DOMAIN_NAME", "base_domain")
domain_root = os.environ.get("DOMAIN_ROOT", "/u01/oracle/user_projects/domains")

#
# Reading arguments  passed from parent script
# ==============================================================
hostname=sys.argv[1]
server=sys.argv[2]
#
# Setting domain path
# ===================
domain_path  = domain_root + '/' + domain_name

#
# Read domain for updates
# =======================
readDomain(domain_path)

#
# Set listen address
# ==================
cd('/')
cd('/Server/'+server)
cmo.setListenAddress(hostname)

# Updating domain
# ==============================
updateDomain()
closeDomain()
exit()
