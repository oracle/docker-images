#!/bin/sh
sample=$1

# Define default command to create medrec domain 
ant $sample

mkdir -p /u01/oracle/weblogic/user_projects/domains/medrec/servers/AdminServer/logs/
touch /u01/oracle/weblogic/user_projects/domains/medrec/servers/AdminServer/logs/AdminServer.log
tail -f /u01/oracle/weblogic/user_projects/domains/medrec/servers/AdminServer/logs/AdminServer.log
