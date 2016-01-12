#!/bin/sh
#
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
#
sample=$1

# Define default command to create medrec domain 
ant $sample

mkdir -p /u01/oracle/user_projects/domains/medrec/servers/AdminServer/logs/
touch /u01/oracle/user_projects/domains/medrec/servers/AdminServer/logs/AdminServer.log
tail -f /u01/oracle/user_projects/domains/medrec/servers/AdminServer/logs/AdminServer.log
