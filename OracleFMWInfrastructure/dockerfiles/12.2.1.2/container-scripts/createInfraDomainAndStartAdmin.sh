#!/bin/bash
#
#
# Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# If AdminServer.log does not exists, container is starting for 1st time
# So it should start NM and also associate with AdminServer
# Otherwise, only start NM (container restarted)
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

#######Random Password Generation########
function rand_pwd(){
    while true; do
         s=$(cat /dev/urandom | tr -dc "A-Za-z0-9" | fold -w 8 | head -n 1)
         if [[ ${#s} -ge 8 && "$s" == *[A-Z]* && "$s" == *[a-z]* && "$s" == *[0-9]*  ]]
         then
             break
         else
             echo "Password does not Match the criteria, re-generating..." >&2
         fi
    done
    echo "${s}"
}

# Set SIGTERM handler
trap _term SIGTERM

# Set SIGKILL handler
trap _kill SIGKILL

	
echo "Configuring Domain for first time run"
echo "====================================="
    
# Auto generate Oracle WebLogic Server admin password
if [ -z ${ADMIN_PASSWORD} ]
then
    # Auto generate Oracle WebLogic Server admin password
    ADMIN_PASSWORD=$(rand_pwd)
    echo ""
    echo "    Oracle WebLogic Server Password Auto Generated :"
    echo ""
    echo "    ----> 'weblogic' admin password: $ADMIN_PASSWORD"
    echo ""
fi;
     
if [ -z ${DB_SCHEMA_PASSWORD} ]
then
    # Auto generate Oracle Database Schema password
    temp_pwd=$(rand_pwd)
    #Password should not start with a number for database
    f_str=`echo $temp_pwd|cut -c1|tr [0-9] [A-Z]`
    s_str=`echo $temp_pwd|cut -c2-`
    DB_SCHEMA_PASSWORD=${f_str}${s_str}
    echo ""
    echo "    Database Schema password Auto Generated :"
    echo ""
    echo "    ----> Database schema password: $DB_SCHEMA_PASSWORD"
    echo ""
fi
    
# Check that the User has passed on all the details needed to configure this image
# Settings to call RCU....
echo "CONNECTION_STRING=${CONNECTION_STRING:?"Please set CONNECTION_STRING for connecting to the Database"}"
echo "RCUPREFIX=${RCUPREFIX:?"Please set RCUPREFIX for the database schemas"}"
echo "DOMAIN_NAME=${DOMAIN_NAME:?"Please set DOMAIN_NAME for creating the new Domain"}"

RUN_RCU="true"
CONTAINERCONFIG_DIR=/u01/oracle/ContainerData
export CONNECTION_STRING=$CONNECTION_STRING
export RCUPREFIX=$RCUPREFIX

export DB_USERNAME=$DB_USERNAME
export DB_PASSWORD=$DB_PASSWORD
export ADMIN_PASSWORD=$ADMIN_PASSWORD
export DB_SCHEMA_PASSWORD=$DB_SCHEMA_PASSWORD

export jdbc_url="jdbc:oracle:thin:@"$CONNECTION_STRING

#Set the password for RCU
echo -e $DB_PASSWORD"\n"$DB_SCHEMA_PASSWORD > /u01/oracle/pwd.txt

echo "Loading RCU Phase"
echo "================="

echo "CONNECTION_STRING=$CONNECTION_STRING"
echo "RCUPREFIX=$RCUPREFIX"
echo "DB_PASSWORD=$DB_PASSWORD"
echo "jdbc_url=$jdbc_url"
echo "ADMIN_PASSWORD=$ADMIN_PASSWORD"
echo "DB_SCHEMA_PASSWORD=$DB_SCHEMA_PASSWORD"
echo "DB_USERNAME=$DB_USERNAME"
echo "DOMAIN_HOME: $DOMAIN_HOME"

#Only call RCU the first time we create the domain
if [ -e $CONTAINERCONFIG_DIR/RCU.$RCUPREFIX.suc ]
then
    #RCU has already been executed successfully, no need to rerun
    RUN_RCU="false"
    echo "SOA RCU has already been loaded.. skipping"
fi

if [ "$RUN_RCU" == "true" ]
then
    echo "Loading SOA RCU into database"
    # Run the RCU to load the schemas into the database
    /u01/oracle/oracle_common/bin/rcu -silent -createRepository -databaseType ORACLE -connectString $CONNECTION_STRING -dbUser $DB_USERNAME -dbRole sysdba -useSamePasswordForAllSchemaUsers true -selectDependentsForComponents true -schemaPrefix $RCUPREFIX -component MDS -component MDS -component IAU -component IAU_APPEND -component IAU_VIEWER -component OPSS  -component WLS  -component STB -f < /u01/oracle/pwd.txt >> /u01/oracle/RCU.out
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
            exit
        fi
    fi

    # cleanup : remove the password file for security
    rm -f "/u01/oracle/pwd.txt" 
fi

# Create an Infrastructure domain
# set environments needed for the script to work
ADD_DOMAIN=1
export MW_HOME="/u01/oracle"
export WL_HOME="/u01/oracle/wlserver"
export ADMIN_USER="weblogic"
export DOMAIN_ROOT="/u01/oracle/user_projects/domains"
export DOMAIN_HOME="${DOMAIN_ROOT}/${DOMAIN_NAME}"


echo "MW_HOME: $MW_HOME"
echo "WL_HOME: $WL_HOME"
echo "ADMIN_USER: $ADMIN_USER"
echo "DOMAIN_ROOT: $DOMAIN_ROOT"
echo "DOMAIN HOME: $DOMAIN_HOME"

if [ ! -f ${DOMAIN_HOME}/servers/AdminServer/logs/AdminServer.log ]; then
    ADD_DOMAIN=0
fi

# Create Domain only if 1st execution
if [ $ADD_DOMAIN -eq 0 ]; 
then
	

     echo "Domain Configuration Phase"
     echo "=========================="
    
     wlst.sh -skipWLSModuleScanning /u01/oracle/container-scripts/createInfraDomain.py -oh $ORACLE_HOME -jh $JAVA_HOME -parent $DOMAIN_ROOT -name $DOMAIN_NAME -user $ADMIN_USER -password $ADMIN_PASSWORD -rcuDb $CONNECTION_STRING -rcuPrefix $RCUPREFIX -rcuSchemaPwd $DB_SCHEMA_PASSWORD
     retval=$?

     echo  "RetVal from Domain creation $retval"
      
     if [ $retval -ne 0 ]; 
     then
         echo "Domain Creation Failed.. Please check the Domain Logs"
         exit
     fi

     # Create the security file to start the server(s) without the password prompt
     mkdir -p ${DOMAIN_HOME}/servers/AdminServer/security/ 
     echo "username=weblogic" > ${DOMAIN_HOME}/servers/AdminServer/security/boot.properties 
     echo "password=$ADMIN_PASSWORD" >> ${DOMAIN_HOME}/servers/AdminServer/security/boot.properties 

     mkdir -p ${DOMAIN_HOME}/servers/infra_server1/security/ 
     echo "username=weblogic" > ${DOMAIN_HOME}/servers/infra_server1/security/boot.properties
     echo "password="$ADMIN_PASSWORD >> ${DOMAIN_HOME}/servers/infra_server1/security/boot.properties

     ${DOMAIN_HOME}/bin/setDomainEnv.sh 
fi

echo "Starting the Admin Server"
echo "=========================="

# Start Admin Server and tail the logs
${DOMAIN_HOME}/startWebLogic.sh
touch ${DOMAIN_HOME}/servers/AdminServer/logs/AdminServer.log
tail -f ${DOMAIN_HOME}/servers/AdminServer/logs/AdminServer.log &

childPID=$!
wait $childPID
