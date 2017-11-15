# Copyright (c) 2014-2016 Oracle and/or its affiliates. All rights reserved.
#
#
# =============================
import os
import socket

execfile('/u01/oracle/commonfuncs.py')

# NodeManager details
nmhost = os.environ.get('NM_HOST', socket.gethostbyname(hostname))
nmport = os.environ.get('NM_PORT', '5556')

print("Hostname : [%s]" % hostname)
print("Username : [%s]" % admin_username)
print("Password : [%s]" % admin_password)
print("Admin Host : [%s]" % admin_host)
print("Admin Port : [%s]" % admin_port)
print("NodeMgr : [%s]" % nmname)

# Connect to the AdminServer
# ==========================
connectToAdmin()

print("Connect Successfull. Exiting ...")

exit()
