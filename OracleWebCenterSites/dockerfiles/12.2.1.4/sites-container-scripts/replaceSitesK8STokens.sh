#!/bin/sh
#
# Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Description: Every time on run of Managed Container a new IP address might get generated. So there is a need for replacement of managedserver IP address in jbossTicketCacheReplicationConfig.xml
#
export DOMAIN_NAME=$DOMAIN_NAME
export DOMAIN_ROOT="/u01/oracle/user_projects/domains"
export DOMAIN_HOME="${DOMAIN_ROOT}/${DOMAIN_NAME}"

echo DOMAIN_HOME: $DOMAIN_HOME

replaceWith=$WCS_MS_NODE_PORT
replaceString=7002

location=/u01/oracle/user_projects/domains/$DOMAIN_NAME/config/fmwconfig/servers/$SITES_SERVER_NAME/config/

echo "replaceSitesK8STokens: Replacement started."

echo The following list of files are found in location ${location} that contains ${replaceString}, will be replaced with ${replaceWith}
grep -rl ${replaceString} ${location}
grep -rl ${replaceString} ${location} | xargs sed -i "s/${replaceString}/${replaceWith}/g"

location=/u01/oracle/user_projects/domains/$DOMAIN_NAME/config/fmwconfig/wcsconfig/

echo The following list of files are found in location ${location} that contains ${replaceString}, will be replaced with ${replaceWith}
grep -rl ${replaceString} ${location}"wcs_properties.json"
grep -rl ${replaceString} ${location}"wcs_properties.json" | xargs sed -i "s/${replaceString}/${replaceWith}/g"

echo "replaceSitesK8STokens: Replacement done successfully."