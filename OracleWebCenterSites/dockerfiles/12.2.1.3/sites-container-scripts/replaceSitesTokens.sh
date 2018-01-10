#!/bin/sh
#
# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Description: Every time on run of Managed Container a new IP address might get generated. So there is a need for replacement of managedserver IP address in jbossTicketCacheReplicationConfig.xml
#
replaceWith=$DOCKER_HOST
replaceString=$WCSITES_ADMIN_HOSTNAME

location="/u01/oracle/user_projects/domains/base_domain/wcsites/wcsites/config/"

echo The following list of files are found in location ${location} that contains ${replaceString}, will be replaced with ${replaceWith}
#grep -rl ${replaceString} ${location} | xargs sed -i "s/${replaceString}/${replaceWith}/g"
grep -rl --exclude="jbossTicketCacheReplicationConfig.xml" ${replaceString} ${location}
grep -rl --exclude="jbossTicketCacheReplicationConfig.xml" ${replaceString} ${location} | xargs sed -i "s/${replaceString}/${replaceWith}/g"