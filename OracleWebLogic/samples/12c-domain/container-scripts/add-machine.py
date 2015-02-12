#
# Script to add NodeManager automatically to the domain's AdminServer running on 'wlsadmin'.
#
# Since: October, 2014
# Author: bruno.borges@oracle.com
#
# =============================
import socket
import os

username = os.getenv('ADMIN_USERNAME', 'weblogic')
password = os.environ.get("ADMIN_PASSWORD")
adminurl = os.environ.get("ADMIN_URL", 't3://wlsadmin:7001')
machinename = os.environ.get('CONTAINER_NAME', "nodemanager_" + socket.gethostname())
listenaddress = os.environ.get('NM_HOST', socket.gethostbyname(socket.gethostname()))
listenport = os.environ.get('NM_PORT', '5556')

connect(username, password, adminurl)
edit()
startEdit()
cd('/')
cmo.createMachine(machinename)
cd('/Machines/' + machinename +'/NodeManager/' + machinename)
cmo.setListenPort(int(listenport))
cmo.setListenAddress(listenaddress)
save()
activate()
exit()
