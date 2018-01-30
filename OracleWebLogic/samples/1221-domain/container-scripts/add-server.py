# Copyright (c) 2014-2016 Oracle and/or its affiliates. All rights reserved.
#
# Script to create and add a Managed Server automatically to the domain's AdminServer running on 'wlsadmin'.
#
# Since: October, 2014
# Author: bruno.borges@oracle.com
#
# =============================
import os
import random
import string
import socket

execfile('/u01/oracle/commonfuncs.py')

# Functions
def randomName():
  return ''.join([random.choice(string.ascii_letters + string.digits) for n in xrange(6)])

# AdminServer details
cluster_name = os.environ.get("CLUSTER_NAME", "DockerCluster")

# ManagedServer details
msinternal = socket.gethostbyname(hostname)
msname = os.environ.get('MS_NAME', 'ManagedServer-%s@%s' % (randomName(), hostname))
mshost = os.environ.get('MS_HOST', msinternal)
msport = os.environ.get('MS_PORT', '7002')
memargs = os.environ.get('USER_MEM_ARGS', '')

# Connect to the AdminServer
# ==========================
connectToAdmin()

# Create a ManagedServer
# ======================
editMode()
cd('/')
cmo.createServer(msname)

cd('/Servers/' + msname)
cmo.setMachine(getMBean('/Machines/%s' % nmname))
cmo.setCluster(getMBean('/Clusters/%s' % cluster_name))

# Default Channel for ManagedServer
# ---------------------------------
cmo.setListenAddress(mshost)
cmo.setListenPort(int(msport))
cmo.setListenPortEnabled(true)
cmo.setExternalDNSName(mshost)

# Disable SSL for this ManagedServer
# ----------------------------------
cd('/Servers/%s/SSL/%s' % (msname, msname))
cmo.setEnabled(false)

# Custom Channel for ManagedServer
# --------------------------------
#cd('/Servers/' + msname)
#cmo.createNetworkAccessPoint('Channel-0')

#cd('/Servers/' + msname + '/NetworkAccessPoints/Channel-0')
#cmo.setProtocol('t3')
#cmo.setEnabled(true)
#cmo.setPublicAddress(mshost)
#cmo.setPublicPort(int(msport))
#cmo.setListenAddress(msinternal)
#cmo.setListenPort(int(msport))
#cmo.setHttpEnabledForThisProtocol(true)
#cmo.setTunnelingEnabled(false)
#cmo.setOutboundEnabled(false)
#cmo.setTwoWaySSLEnabled(false)
#cmo.setClientCertificateEnforced(false)

# Custom Startup Parameters because NodeManager writes wrong AdminURL in startup.properties
# -----------------------------------------------------------------------------------------
cd('/Servers/%s/ServerStart/%s' % (msname, msname))
arguments = '-Djava.security.egd=file:/dev/./urandom -Dweblogic.Name=%s -Dweblogic.management.server=http://%s:%s %s' % (msname, admin_host, admin_port, memargs)
cmo.setArguments(arguments)
saveActivate()

# Start Managed Server
# ------------
try:
    start(msname, 'Server')
except:
    dumpStack()

# Exit
# =========
exit()
