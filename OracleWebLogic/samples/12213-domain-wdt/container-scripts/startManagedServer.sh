#!/bin/bash
#
#Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Start the Domain.

PROPERTIES_FILE=/u01/oracle/properties/domain.properties
if [ ! -e "$PROPERTIES_FILE" ]; then
    echo "A properties file with variable definitions needs to be supplied."
    exit
fi

DOMAIN_NAME=`awk '{print $1}' $PROPERTIES_FILE | grep ^DOMAIN_NAME= | cut -d "=" -f2`
if [ -z "$DOMAIN_NAME" ]; then
    echo "The domain name is blank.  The domain name must be set in the properties file."
    exit
fi

USER=`awk '{print $1}' $PROPERTIES_FILE | grep ^username= | cut -d "=" -f2`
if [ -z "$USER" ]; then
    echo "The admin username is blank.  The admin username must be set in the properties file."
    exit
fi

PASS=`awk '{print $1}' $PROPERTIES_FILE | grep ^password= | cut -d "=" -f2`
if [ -z "$PASS" ]; then
    echo "The admin password is blank.  The admin password must be set in the properties file."
    exit
fi

ADMIN_HOST=`awk '{print $1}' $PROPERTIES_FILE | grep ^ADMIN_HOST= | cut -d "=" -f2`
if [ -z "$ADMIN_HOST" ]; then
    echo "The admin host is blank.  The admin host must be set in the properties file."
    exit
fi

ADMIN_PORT=`awk '{print $1}' $PROPERTIES_FILE | grep ^ADMIN_PORT= | cut -d "=" -f2`
if [ -z "$ADMIN_PORT" ]; then
    echo "The admin port is blank.  The admin port must be set in the properties file."
    exit
fi

#Define DOMAIN_HOME
export DOMAIN_HOME=/u01/oracle/user_projects/domains/$DOMAIN_NAME

mkdir -p $DOMAIN_HOME/servers/$MS_NAME/security
echo username=$USER > $DOMAIN_HOME/servers/$MS_NAME/security/boot.properties
echo password=$PASS >> $DOMAIN_HOME/servers/$MS_NAME/security/boot.properties

# Start Managed Server and tail the logs
${DOMAIN_HOME}/bin/startManagedWebLogic.sh $MS_NAME http://$ADMIN_HOST:$ADMIN_PORT
touch ${DOMAIN_HOME}/servers/$MS_NAME/logs/${MS_NAME}.log
tail -f ${DOMAIN_HOME}/servers/$MS_NAME/logs/${MS_NAME}.log &

childPID=$!
wait $childPID
