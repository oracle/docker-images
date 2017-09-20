#!/usr/bin/python
#
# Author:swati.mukundan@oracle.com
#
# Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# SOA on Docker Default Domain
#
# Updates the listen address for managed server with the IP address of the host.
#
# Since : April, 2016
# Author: swati.mukundan@oracle.com
# ==============================================
import sys
import os
import string
import socket

# Assigning values to variables
# ==================================
domain_name  = os.environ.get("DOMAIN_NAME", "InfraDomain")
domain_root = os.environ.get("DOMAIN_ROOT", "/u01/oracle/user_projects/domains")

# Reading db details and schema prefix passed from parent script
# ==============================================================
print str(sys.argv[0]) + " called with the following sys.argv array:"
for index, arg in enumerate(sys.argv):
    print "sys.argv[" + str(index) + "] = " + str(sys.argv[index])

server=sys.argv[1]
hostname = socket.gethostname()
infra_host= socket.gethostbyname(hostname)
print hostname
print  infra_host

# Default Channel for ManagedServer
# ---------------------------------
# Setting domain path
# ===================
domain_path  = domain_root + '/' + domain_name
print domain_path

# Read domain for updates
# =======================
readDomain(domain_path)

# Set listen address
# ==================
cd('/')
cd('/Servers/'+server)
cmo.setListenAddress(infra_host)

# Creating domain
# ==============================
updateDomain()
closeDomain()
exit()
