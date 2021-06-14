#
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Stops the WebLogic server
#

import sys

if len(sys.argv) < 2:
   print 'Expected number of arguments not passed!!'
   sys.exit(1)

# Standard settings
serverUrl=sys.argv[1]
wlsUsername=sys.argv[2]
wlsPassword=sys.stdin.readline()
wlsPassword=wlsPassword.strip()

connect(wlsUsername, wlsPassword, serverUrl)
try:
   shutdown(ignoreSessions = 'true', timeOut = 360, block = 'true')
   disconnect()
except:
   # ignore any error here
   pass
