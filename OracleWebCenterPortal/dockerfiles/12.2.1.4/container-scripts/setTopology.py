#!/usr/bin/python
# Copyright (c) 2020, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
import sys

admin_name = os.environ['ADMIN_USERNAME']
admin_pass = os.environ['ADMIN_PASSWORD']
admin_port = os.environ['ADMIN_PORT']
admin_host = sys.argv[1]
url = admin_host + ':' + admin_port

connect(admin_name, admin_pass, url)

edit()
startEdit()

cd('/Servers/WC_Portal')
cmo.setMachine(getMBean('/Machines/machine1'))
cmo.setCluster(getMBean('/Clusters/wcp_cluster1'))

cd('/CoherenceClusterSystemResources/defaultCoherenceCluster/CoherenceClusterResource/defaultCoherenceCluster/CoherenceClusterParams/defaultCoherenceCluster/CoherenceClusterWellKnownAddresses/defaultCoherenceCluster')
cmo.createCoherenceClusterWellKnownAddress('WKA-0')

cd('/CoherenceClusterSystemResources/defaultCoherenceCluster/CoherenceClusterResource/defaultCoherenceCluster/CoherenceClusterParams/defaultCoherenceCluster/CoherenceClusterWellKnownAddresses/defaultCoherenceCluster/CoherenceClusterWellKnownAddresses/WKA-0')
cmo.setListenAddress('localhost')

save()
activate()

disconnect()
exit()
