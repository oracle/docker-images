#
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This script pings the database indefinitely until it is available.

import os
import sys
from __builtin__ import False
from oracle.essbase.syncmidtierdb import DBConnectionDetails
from java.util import Properties
from java.sql  import DriverManager

def noneIfNoValue(v):
   if v is None or v == 'NO_VALUE':
      return None
   return v

try:
   if len(sys.argv) < 4:
      print 'Expected number of arguments not passed!!'
      sys.exit(1)

   databaseType = sys.argv[1]
   databaseConnectStr = sys.argv[2]
   databaseUser = sys.argv[3]
   databaseRole = noneIfNoValue(sys.argv[4])

   interval = 0
   if len(sys.argv) > 4:
      interval = int(sys.argv[5])

   databaseType = databaseType.lower()
   databaseUserPassword=sys.stdin.readline()
   databaseUserPassword=databaseUserPassword.strip()

   connectionDetails = DBConnectionDetails(databaseType, databaseConnectStr)

   # Update all of the datasources
   jdbcUrl = connectionDetails.getJDBCUrl()
   jdbcDriverName = connectionDetails.getDriverName()

   if databaseType == "oracle" and databaseRole is not None:
      databaseUser = "%s as %s" % (databaseUser, databaseRole)

   props = Properties()
   props.setProperty("user", databaseUser)
   props.setProperty("password", databaseUserPassword)
   props.setProperty("oracle.net.CONNECT_TIMEOUT", "10")

   success = False
   while not success:

      time.sleep(interval)
      print "Pinging database at url %s " % jdbcUrl

      conn = None
      try:
        conn = DriverManager.getConnection(jdbcUrl, props)
        success = True
      except java.sql.SQLException, e:
        code = e.getErrorCode()
        print "ERROR: %s " % e.getMessage()     
        success = False

      if conn is not None:
        conn.close()

      if interval <= 0:
        sys.exit(1)


except:
   dumpStack()
   raise

print "Success"
sys.exit(0)

