#
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This script writes out the boot.properties file securely

import os
import sys

try:

   if len(sys.argv) < 2:
      print 'Expected number of arguments not passed!!'
      sys.exit(1)

   domainHome=sys.argv[1]
   serverName=sys.argv[2]

   wlsUsername=sys.stdin.readline()
   wlsUsername=wlsUsername.strip()

   wlsPassword=sys.stdin.readline()
   wlsPassword=wlsPassword.strip()

   wlsPasswordEncrypted=encrypt(wlsPassword, domainHome)

   if not os.path.exists(domainHome + "/servers/" + serverName + "/security"):
      os.makedirs(domainHome + "/servers/" + serverName + "/security")
   
   f = open(domainHome + "/servers/" + serverName + "/security/boot.properties", "w")
   f.write("username=" + wlsUsername + "\n")
   f.write("password=" + wlsPasswordEncrypted + "\n")
   f.close()

except:
   dumpStack()
   raise
