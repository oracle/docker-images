#
# Script to add NodeManager automatically to the domain's AdminServer running on 'wlsadmin'.
#
# Since: October, 2014
# Author: bruno.borges@oracle.com
#
# =============================
import os
import socket

# Functions
def editMode():
  edit()
  startEdit()

def editActivate():
  save()
  activate(block="true")

# Variables
# =========

# AdminServer details
username  = os.environ.get('ADMIN_USERNAME', 'weblogic')
password  = os.environ.get('ADMIN_PASSWORD')
adminhost = os.environ.get('ADMIN_HOST', 'wlsadmin')
adminport = os.environ.get('ADMIN_PORT', '8001')

# NodeManager details
nmname = os.environ.get('NM_NAME', 'Machine-' + socket.gethostname())
nmhost = os.environ.get('NM_HOST', socket.gethostbyname(socket.gethostname()))
nmport = os.environ.get('NM_PORT', '5556')

# Connect to the AdminServer
# ==========================
connect(username, password, 't3://' + adminhost + ':' + adminport)

# Create a Machine
# ================
editMode()
cd('/')
cmo.createMachine(nmname)
cd('/Machines/' + nmname +'/NodeManager/' + nmname)
cmo.setListenPort(int(nmport))
cmo.setListenAddress(nmhost)
cmo.setNMType('Plain')
editActivate()

# Exit
# ====
exit()
