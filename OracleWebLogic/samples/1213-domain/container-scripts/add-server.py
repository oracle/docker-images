#
# Script to add NodeManager automatically to the domain's AdminServer running on 'wlsadmin'.
#
# Since: October, 2014
# Author: bruno.borges@oracle.com
#
# =============================
import os
import random
import string
import socket

# Functions
def randomName():
  return ''.join([random.choice(string.ascii_letters + string.digits) for n in xrange(16)])

def editMode():
  edit()
  startEdit()
  
def editActivate():
  save()
  activate(block="true")
  
# AdminServer details
username  = os.environ.get('ADMIN_USERNAME', 'weblogic')
password  = os.environ.get('ADMIN_PASSWORD')
adminhost = os.environ.get('ADMIN_HOST', 'wlsadmin')
adminport = os.environ.get('ADMIN_PORT', '8001')

# NodeManager details
nmname = os.environ.get('NM_NAME', 'Machine-' + socket.gethostname())

# ManagedServer details
msinternal = socket.gethostbyname(socket.gethostname())
msname = os.environ.get('MS_NAME', 'ManagedServer-' + socket.gethostname() + '-' + randomName())
mshost = os.environ.get('MS_HOST', socket.gethostbyname(socket.gethostname()))
msport = os.environ.get('MS_PORT', '7001')
memargs = os.environ.get('USER_MEM_ARGS', '-Xms256m -Xmx512m -XX:MaxPermSize=512m')

# Connect to the AdminServer
# ==========================
connect(username, password, 't3://' + adminhost + ':' + adminport)

# Create a ManagedServer
# ======================
editMode()
cd('/')
cmo.createServer(msname)

cd('/Servers/' + msname)
cmo.setMachine(getMBean('/Machines/' + nmname))
cmo.setCluster(None)

# Default Channel for ManagedServer
# ---------------------------------
cmo.setListenAddress(msinternal)
cmo.setListenPort(int(msport))
cmo.setListenPortEnabled(true)
cmo.setExternalDNSName(mshost)

# Disable SSL for this ManagedServer
# ----------------------------------
cd('/Servers/' + msname + '/SSL/' + msname)
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
cd('/Servers/' + msname + '/ServerStart/' + msname)
arguments = '-Djava.security.egd=file:/dev/./urandom -Dweblogic.Name=' + msname + ' -Dweblogic.management.server=http://' + adminhost + ':' + adminport + ' ' + memargs
cmo.setArguments(arguments)
editActivate()

# Start Managed Server
# ------------
try:
    start(msname, 'Server')
except:
    dumpStack()

# Exit
# =========
exit()
