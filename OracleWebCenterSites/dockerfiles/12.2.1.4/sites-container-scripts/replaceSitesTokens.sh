#!/bin/sh
#
# Copyright (c) 2019, 2020 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Description: Every time on run of Managed Container a new IP address might get generated. So there is a need for replacement of managedserver IP address in jbossTicketCacheReplicationConfig.xml
#
replaceWith=$DOCKER_HOST
replaceString=$WCSITES_ADMIN_HOSTNAME

location=$DOMAIN_HOME/config/fmwconfig/servers/${SITES_SERVER_NAME}1/config/

echo The following list of files are found in location ${location} that contains ${replaceString}, will be replaced with ${replaceWith}
grep -rl ${replaceString} ${location}
grep -rl ${replaceString} ${location} | xargs sed -i "s/${replaceString}/${replaceWith}/g"

location=$DOMAIN_HOME/config/fmwconfig/wcsconfig/

echo The following list of files are found in location ${location} that contains ${replaceString}, will be replaced with ${replaceWith}
grep -rl ${replaceString} ${location}"wcs_properties.json"
grep -rl ${replaceString} ${location}"wcs_properties.json" | xargs sed -i "s/${replaceString}/${replaceWith}/g"

