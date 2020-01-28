#!/bin/sh
#
# Copyright (c) 2019, 2020 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Description: Every time on run of Managed Container a new IP address might get generated. So there is a need for replacement of managedserver IP address in jbossTicketCacheReplicationConfig.xml
#
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

