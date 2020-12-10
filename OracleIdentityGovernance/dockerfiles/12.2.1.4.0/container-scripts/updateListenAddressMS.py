#!/usr/bin/python
#
# Copyright (c) 2020 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Author: OIG Development
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
admin_host = sys.argv[4]
admin_port = sys.argv[5]
admin_usr = sys.argv[6]
admin_pwd = sys.argv[7]
serverPath = '/Servers/' + server

#
# Setting domain path
# ===================
domain_path  = domain_home
admin_url = 't3://'+admin_host + ":" + admin_port
#
# Read domain for updates
# =======================
# Connect to Edit tree(domain_path) and start Edit Session
print("Admin URL -> " + admin_url)
print("Server Path -> " + serverPath)
connect(admin_usr,admin_pwd, admin_url)
edit()
startEdit()
#
# Set listen address
# ==================
cd(serverPath)
cmo.setListenAddress(manserver_host)
cmo.setExternalDNSName(exthost)

# Activating Changes
# ===============
activate()
exit()

