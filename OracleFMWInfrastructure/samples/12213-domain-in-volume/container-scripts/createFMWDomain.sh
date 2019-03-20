#!/bin/bash
#
#
# Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
#Define CUSTOM_DOMAIN_HOME
export DOMAIN_HOME=$CUSTOM_DOMAIN_ROOT/$CUSTOM_DOMAIN_NAME
echo "Domain Home is:  $DOMAIN_HOME"
echo "Domain Root is:  $CUSTOM_DOMAIN_ROOT"

########### SIGTERM handler ############
function _term() {
   echo "Stopping container."
   echo "SIGTERM received, shutting down the server!"
   ${DOMAIN_HOME}/bin/stopWebLogic.sh
}

########### SIGKILL handler ############
function _kill() {
   echo "SIGKILL received, shutting down the server!"
   kill -9 $childPID
}

# Set SIGTERM handler
trap _term SIGTERM

# Set SIGKILL handler
trap _kill SIGKILL

echo "Configuring Domain for first time "
echo "Start the Admin and Managed Servers  "
echo "====================================="

# Check that the User has passed on all the details needed to configure this image
# Settings to call RCU....
echo "CUSTOM_CONNECTION_STRING=${CUSTOM_CONNECTION_STRING:?"Please set CONNECTION_STRING for connecting to the Database"}"
echo "CUSTOM_RCUPREFIX=${CUSTOM_RCUPREFIX:?"Please set RCUPREFIX for the database schemas"}"
echo "CUSTOM_DOMAIN_NAME=${CUSTOM_DOMAIN_NAME:?"Please set DOMAIN_NAME for creating the new Domain"}"
echo "DOMAIN_HOME=$DOMAIN_HOME"

RUN_RCU="true"
CONTAINERCONFIG_DIR=/u01/oracle/ContainerData

export jdbc_url="jdbc:oracle:thin:@"$CUSTOM_CONNECTION_STRING

echo "Loading RCU Phase"
echo "================="

echo "CONNECTION_STRING=$CUSTOM_CONNECTION_STRING"
echo "RCUPREFIX=$CUSTOM_RCUPREFIX"
echo "jdbc_url=$jdbc_url"


# Create an Infrastructure domain
# set environments needed for the script to work
ADD_DOMAIN=1

if [ ! -f ${DOMAIN_HOME}/servers/${CUSTOM_ADMIN_NAME}/logs/${CUSTOM_ADMIN_NAME}.log ]; then
    ADD_DOMAIN=0
fi

# Create Domain only if 1st execution
if [ $ADD_DOMAIN -eq 0 ];
then
   echo "Creating Domain 1st execution"
   mkdir -p $ORACLE_HOME/properties
   # Create Domain only if 1st execution
   SEC_PROPERTIES_FILE=/u01/oracle/properties/domain_security.properties
   if [ ! -e "$SEC_PROPERTIES_FILE" ]; then
      echo "A properties file with the username and password needs to be supplied."
      exit
   fi

   # Get Username
   USER=`awk '{print $1}' $SEC_PROPERTIES_FILE | grep username | cut -d "=" -f2`
   if [ -z "$USER" ]; then
      echo "The domain username is blank.  The Admin username must be set in the properties file."
      exit
   fi
   # echo "Username: $USER"
   # Get Password
   PASS=`awk '{print $1}' $SEC_PROPERTIES_FILE | grep password | cut -d "=" -f2`
   if [ -z "$PASS" ]; then
      echo "The domain password is blank.  The Admin password must be set in the properties file."
      exit
   fi
   # echo "Password: $PASS"
   # Get Database Username
   DB_USER=`awk '{print $1}' $SEC_PROPERTIES_FILE | grep db_user | cut -d "=" -f2`
   if [ -z "$DB_USER" ]; then
      echo "The domain username is blank.  The Admin username must be set in the properties file."
      exit
   fi
   # echo "Database Username $DB_USER"
   # Get Database Password
   DB_PASS=`awk '{print $1}' $SEC_PROPERTIES_FILE | grep db_pass | cut -d "=" -f2`
   if [ -z "$DB_PASS" ]; then
      echo "The domain password is blank.  The Admin password must be set in the properties file."
      exit
   fi
   # echo "Database Password $DB_PASS"
   # Get databasse Schema Password
   DB_SCHEMA_PASS=`awk '{print $1}' $SEC_PROPERTIES_FILE | grep db_schema | cut -d "=" -f2`
   if [ -z "$DB_SCHEMA_PASS" ]; then
      echo "The databse schema password is blank.  The database schema password must be set in the properties file."
      exit
   fi
   # echo "Database Schema Password: $DB_SCHEMA_PASS"


   #Only call RCU the first time we create the domain
   if [ -e $CONTAINERCONFIG_DIR/RCU.$CUSTOM_RCUPREFIX.suc ]
   then
       #RCU has already been executed successfully, no need to rerun
       RUN_RCU="false"
       echo "SOA RCU has already been loaded.. skipping"
   fi

   if [ "$RUN_RCU" == "true" ]
   then
       #Set the password for RCU
       echo -e ${DB_PASS}"\n"${DB_SCHEMA_PASS} > /u01/oracle/pwd.txt
       echo "Loading SOA RCU into database"
       # Run the RCU to load the schemas into the database
       /u01/oracle/oracle_common/bin/rcu -silent -createRepository -databaseType ORACLE -connectString ${CONNECTION_STRING} -dbUser ${DB_USER} -dbRole sysdba -useSamePasswordForAllSchemaUsers true -selectDependentsForComponents true -schemaPrefix ${CUSTOM_RCUPREFIX} -component MDS -component MDS -component IAU -component IAU_APPEND -component IAU_VIEWER -component OPSS  -component WLS  -component STB -f < /u01/oracle/pwd.txt >> /u01/oracle/RCU.out
       retval=$?

       if [ $retval -ne 0 ];
       then
           echo  "RCU has some error "
           #RCU was already called once and schemas are in the database
           #continue with Domain creation
           grep -q "RCU-6016 The specified prefix already exists" "/u01/oracle/RCU.out"
           if [ $? -eq 0 ] ; then
             echo  "RCU has already loaded schemas into the Database"
             echo  "RCU Ignore error"
           else
               echo "RCU Loading Failed.. Please check the RCU logs"
               cat /u01/oracle/RCU.out
               exit
           fi
       fi

       # cleanup : remove the password file for security
       rm -f "/u01/oracle/pwd.txt"
   fi

        echo "Domain Configuration Phase"
        echo "=========================="
        wlst.sh -skipWLSModuleScanning /u01/oracle/container-scripts/createFMWDomain.py -oh ${ORACLE_HOME} -jh ${JAVA_HOME} -parent ${CUSTOM_DOMAIN_ROOT} -name ${CUSTOM_DOMAIN_NAME} -user ${USER} -password ${PASS} -rcuDb ${CONNECTION_STRING} -rcuPrefix ${CUSTOM_RCUPREFIX} -rcuSchemaPwd ${DB_SCHEMA_PASS} -adminListenPort ${CUSTOM_ADMIN_LISTEN_PORT} -adminName ${CUSTOM_ADMIN_NAME} -managedNameBase ${CUSTOM_MANAGED_BASE_NAME} -managedServerPort ${CUSTOM_MANAGEDSERVER_PORT} -prodMode ${CUSTOM_PRODUCTION_MODE} -managedServerCount ${CUSTOM_MANAGED_SERVER_COUNT} -clusterName ${CUSTOM_CLUSTER_NAME}
        retval=$?

        echo  "RetVal from Domain creation $retval"

        if [ $retval -ne 0 ];
        then
            echo "Domain Creation Failed.. Please check the Domain Logs"
            exit
        fi

        # Create the security file to start the server(s) without the password prompt
        mkdir -p ${DOMAIN_HOME}/servers/${CUSTOM_ADMIN_NAME}/security/
        echo "username=${USER}" >> ${DOMAIN_HOME}/servers/${CUSTOM_ADMIN_NAME}/security/boot.properties
        echo "password=${PASS}" >> ${DOMAIN_HOME}/servers/${CUSTOM_ADMIN_NAME}/security/boot.properties

        ${DOMAIN_HOME}/bin/setDomainEnv.sh
   fi

   #Set Java options
   export JAVA_OPTIONS=${JAVA_OPTIONS}
   echo "Java Options: ${JAVA_OPTIONS}"

   echo "Starting the Admin Server"
   echo "=========================="

   # Start Admin Server and tail the logs
   ${DOMAIN_HOME}/startWebLogic.sh
   touch ${DOMAIN_HOME}/servers/${CUSTOM_ADMIN_NAME}/logs/${CUSTOM_ADMIN_NAME}.log
   tail -f ${DOMAIN_HOME}/servers/${CUSTOM_ADMIN_NAME}/logs/${CUSTOM_ADMIN_NAME}.log &

   childPID=$!
   wait $childPID
