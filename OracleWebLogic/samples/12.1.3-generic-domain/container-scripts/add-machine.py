# Script to add NodeManager automatically to the domain's AdminServer running on 'wlsadmin'.
#
# - DOCKER_CONTAINER_NAME: unique name for this container
#   Give a value with $ docker run -e DOCKER_CONTAINER_NAME=some_unique_name
# - ADMIN_PASSWORD: provided during image build. See Dockerfile sample
# - NM_PORT: provided during image build. See Dockerfile sample
# - ADMIN_ADDRESS: t3 URL of an AdminServer running somewhere.
#   Inform this value as $ docker run -e ADMIN_ADDRESS=t3//some_ip:some_port
# 
# Both containers, the one with NM and the one with AdminServer, must be able to communicate bidirectionally.
# =============================
import socket
import os
machine_name = os.environ['DOCKER_CONTAINER_NAME']
listen_address = socket.gethostbyname(socket.gethostname())
connect('weblogic',os.environ["ADMIN_PASSWORD"], os.environ["ADMIN_ADDRESS"])
edit()
startEdit()
cd('/')
cmo.createMachine(machine_name)
cd('/Machines/' + machine_name +'/NodeManager/' + machine_name)
cmo.setListenPort(int(os.environ["NM_PORT"]))
cmo.setListenAddress(listen_address)
save()
activate()
exit()
