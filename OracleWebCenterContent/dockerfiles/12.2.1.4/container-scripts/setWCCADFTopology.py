#!/usr/bin/python
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
#
# ==============================================

import sys
admin_name = os.environ['ADMIN_USERNAME']
admin_pass = os.environ['ADMIN_PASSWORD']
admin_port = os.environ['ADMIN_PORT']
admin_container  = os.environ['ADMIN_SERVER_CONTAINER_NAME']

url = admin_container + ':' + admin_port

print('url :' + url);

connect(admin_name, admin_pass, url)

edit()
startEdit()

cd('/Servers/WCCADF_server1')
cmo.setMachine(getMBean('/Machines/machine1'))
cmo.setCluster(getMBean('/Clusters/wccadf_cluster1'))

########Add code to change the intradoc hostname and port for WCCADFUI 

save()
activate()

disconnect()
exit()
