#!/bin/bash
#
#Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Start the Domain.

PROPERTIES_FILE=/u01/oracle/properties/domain.properties
if [ ! -e "$PROPERTIES_FILE" ]; then
    echo "A properties file with the username and password needs to be supplied."
    exit
fi

DOMAIN_NAME=`awk '{print $1}' $PROPERTIES_FILE | grep ^DOMAIN_NAME= | cut -d "=" -f2`
if [ -z "$DOMAIN_NAME" ]; then
    echo "The domain name is blank.  The domain name must be set in the properties file."
    exit
fi

USER=`awk '{print $1}' $PROPERTIES_FILE | grep ^username= | cut -d "=" -f2`
if [ -z "$USER" ]; then
    echo "The domain username is blank.  The Admin username must be set in the properties file."
    exit
fi

PASS=`awk '{print $1}' $PROPERTIES_FILE | grep ^password= | cut -d "=" -f2`
if [ -z "$PASS" ]; then
    echo "The domain password is blank.  The Admin password must be set in the properties file."
    exit
fi

#Define DOMAIN_HOME
export DOMAIN_HOME=/u01/oracle/user_projects/domains/$DOMAIN_NAME

mkdir -p ${DOMAIN_HOME}/servers/AdminServer/security/
echo "username=${USER}" >> $DOMAIN_HOME/servers/AdminServer/security/boot.properties
echo "password=${PASS}" >> $DOMAIN_HOME/servers/AdminServer/security/boot.properties

# Start Admin Server and tail the logs
${DOMAIN_HOME}/startWebLogic.sh
touch ${DOMAIN_HOME}/servers/AdminServer/logs/AdminServer.log
tail -f ${DOMAIN_HOME}/servers/AdminServer/logs/AdminServer.log &

childPID=$!
wait $childPID
