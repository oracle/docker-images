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
admin_host = sys.argv[1]

url = admin_container + ':' + admin_port

print('url :' + url);

connect(admin_name, admin_pass, url)

edit()
startEdit()

cd('/Servers/IPM_server1')
cmo.setMachine(getMBean('/Machines/machine1'))
cmo.setCluster(getMBean('/Clusters/ipm_cluster1'))
cd('/Servers/IPM_server1')

save()
activate()

disconnect()
exit()
