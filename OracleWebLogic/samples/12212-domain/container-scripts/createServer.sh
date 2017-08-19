#!/bin/bash
#
#Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
export DOMAIN_HOME=/u01/oracle/user_projects/domains/$DOMAIN_NAME
echo "Domain Home: " $DOMAIN_HOME

if [ -z $ADMIN_PASSWORD ]; then
   echo "      ----> NO 'weblogic' admin password set"
   echo ""
else
   s=${ADMIN_PASSWORD}
   echo "      ----> 'weblogic' admin password: $s"
fi
sed -i -e "s|ADMIN_PASSWORD|$s|g" /u01/oracle/commonfuncs.py



# If log.nm does not exists, container is starting for 1st time
# So it should start NM and also associate with AdminServer, as well Managed Server
# Otherwise, only start NM (container is being restarted)
if [ ! -f /u01/oracle/log.nm ]; then
    ADD_SERVER=1
fi

# Wait for AdminServer to become available for any subsequent operation
/u01/oracle/waitForAdminServer.sh

# Start Node Manager
echo "Starting NodeManager in background..."
nohup $DOMAIN_HOME/bin/startNodeManager.sh > /u01/oracle/log.nm 2>&1 &
echo "NodeManager started."

# Add this 'Machine' and 'ManagedServer' to the AdminServer only if 1st execution
if [ $ADD_SERVER -eq 1 ]; then
  wlst /u01/oracle/add-machine.py
  wlst /u01/oracle/add-server.py
fi

# print log
tail -f /u01/oracle/log.nm $DOMAIN_HOME/servers/*/logs/*.out
