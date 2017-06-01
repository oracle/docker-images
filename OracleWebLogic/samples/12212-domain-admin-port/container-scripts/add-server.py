# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.
#
# Script to create and add a Managed Server automatically to the domain's AdminServer running on 'wlsadmin'.
# 
#
# Since: May, 2017
# Author: amy.roh@oracle.com
#
# =============================
import os
import random
import string
import socket
import sys, getopt


execfile('/u01/oracle/commonfuncs.py')

# Functions
def randomName():
  return ''.join([random.choice(string.ascii_letters + string.digits) for n in xrange(6)])

def getDebugPort():
  try:
    argv = sys.argv
    del argv[0]    # always contains the name of this script
    opts, args = getopt.getopt(argv, "", ["debugPort="])
  except getopt.GetoptError:
    print 'add-server.py [--debugPort=<port>]'
    sys.exit(2)

  for opt, arg in opts:
    if opt == '--debugPort':
      return arg
  return ''

# AdminServer details
cluster_name = os.environ.get("CLUSTER_NAME", "DockerCluster")

# ManagedServer details
msinternal = hostname # socket.gethostbyname(hostname)
msname = os.environ.get('MS_NAME', 'ManagedServer-%s@%s' % (randomName(), hostname))
mshost = os.environ.get('MS_HOST', msinternal)
msport = os.environ.get('MS_PORT', '7001')
memargs = os.environ.get('USER_MEM_ARGS', '')
# To start Managed Servers after enabling the administration port, you must establish an SSL connection to the domain's Administration Server by starting the Managed Server using -Dweblogic.management.server=https://host:admin_port.
administration_port = os.environ.get('ADMINISTRATION_PORT', '9002')

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
# cmo.setListenAddress(msinternal) - by default listen on all interfaces
cmo.setListenPort(int(msport))
cmo.setListenPortEnabled(true)
cmo.setExternalDNSName(mshost)

# Enable two ways SSL for this ManagedServer
# ----------------------------------
cd('/Servers/%s/SSL/%s' % (msname, msname))
cmo.setEnabled(true)
cmo.setHostnameVerifier(None)
cmo.setHostnameVerificationIgnored(true)
cmo.setTwoWaySSLEnabled(true)

# Custom Startup Parameters because NodeManager writes wrong AdminURL in startup.properties
# -----------------------------------------------------------------------------------------
cd('/Servers/%s/ServerStart/%s' % (msname, msname))
arguments = '-Dweblogic.security.SSL.ignoreHostnameVerification=true -Dweblogic.security.TrustKeyStore=DemoTrust -Djava.security.egd=file:/dev/./urandom -Dweblogic.Name=%s -Dweblogic.management.server=https://%s:%s %s' % (msname, admin_host, administration_port, memargs)
debugPort = getDebugPort()
if debugPort != "":
  arguments = arguments + " -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=" + debugPort

cmo.setArguments(arguments)

try :
  saveActivate()
except:
  dumpStack()

# Start Managed Server
# ------------
try:
    start(msname, 'Server')
except:
    dumpStack()

# Exit
# =========
exit()
