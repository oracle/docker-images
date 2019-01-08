#Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Script to create and add NodeManager automatically to the domain's AdminServer running on '$ADMIN_HOST'.
#
# Since: October, 2014
# Author: bruno.borges@oracle.com
#
# =============================
import os
import socket

execfile('/u01/oracle/commonfuncs.py')

# NodeManager details
nmhost = os.environ.get('NM_HOST', socket.gethostbyname(hostname))
nmport = os.environ.get('NM_PORT', '5556')

# Connect to the AdminServer
# ==========================
connectToAdmin()

# Create a Machine
# ================
editMode()

cd('/')
cmo.createMachine(nmname)
cd('/Machines/%s/NodeManager/%s' % (nmname, nmname))
cmo.setListenPort(int(nmport))
cmo.setListenAddress(nmhost)
cmo.setNMType('Plain')

saveActivate()

# Exit
# ====
exit()
