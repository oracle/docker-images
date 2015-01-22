#
# Script to add NodeManager automatically to the domain's AdminServer running on 'wlsadmin'.
# 
# - wlsadmin: name of the linked Docker container with AdminServer running on
# =============================
import socket 
import os

machine_name = os.environ['DOCKER_CONTAINER_NAME']
listen_address = socket.gethostbyname(socket.gethostname())

connect('weblogic',os.environ["ADMIN_PASSWORD"],'t3://wlsadmin:7001')

edit()
startEdit()

# check if machine already exists. If it does, update listen address. If not, create it.
cd('/')
cmo.createMachine(machine_name)

cd('/Machines/' + machine_name +'/NodeManager/' + machine_name)
cmo.setListenAddress(listen_address)

save()
activate()
exit()
