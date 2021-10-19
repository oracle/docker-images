#!/bin/bash
#
#
# Copyright (c) 2021 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
# Author:Arnab Nandi <arnab.x.nandi@oracle.com>
#
#Define DOMAIN_HOME
export DOMAIN_ROOT="/u01/oracle/user_projects/domains"
export DOMAIN_HOME=${DOMAIN_ROOT}/${VERIDATA_DOMAIN_NAME}
export VERIDATA_ADMIN_SERVER=${VERIDATA_ADMIN_SERVER}
echo "Domain Home is: " $DOMAIN_HOME


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

echo "Configuring Domain for first time "
echo "Start the Admin and Managed Servers  "
echo "====================================="

# Check that the User has passed on all the details needed to configure this image
# Settings to call RCU....


echo "SCHEMA_PREFIX=${SCHEMA_PREFIX:?"Please set SCHEMA_PREFIX for the database schemas"}"
echo "VERIDATA_DOMAIN_NAME=${VERIDATA_DOMAIN_NAME:?"Please set VERIDATA_DOMAIN_NAME for creating the new Domain"}"
echo "VERIDATA_USER=${VERIDATA_USER:?"Please set VERIDATA_USER"}"
echo "DATABASE_HOST=${DATABASE_HOST:?"Please set DATABASE_HOST"}"
echo "DATABASE_PORT=${DATABASE_PORT:?"Please set DATABASE_PORT"}"
echo "DATABASE_USER=${DATABASE_USER:?"Please set DATABASE_USER"}"

CONTAINERCONFIG_DIR=${ORACLE_HOME}/user_projects/ContainerData

if [ -z "${SCHEMA_PASSWORD}" ]
then
    # Auto generate Oracle Database Schema password
    temp_pwd=$(rand_pwd)
    #Password should not start with a number for database
    f_str=`echo $temp_pwd|cut -c1|tr [0-9] [A-Z]`
    s_str=`echo $temp_pwd|cut -c2-`
    SCHEMA_PASSWORD=${f_str}${s_str}
    echo ""
    echo "    Database Schema password Auto Generated :"
    echo ""
    echo "    ----> Database schema password: $SCHEMA_PASSWORD"
    echo ""
fi


if [ -z "${VERIDATA_PASSWORD}" ]
then
    # Auto generate Weblogic Administrator password
    temp_pwd=$(rand_pwd)
    #Password should not start with a number for domain
    f_str=`echo $temp_pwd|cut -c1|tr [0-9] [A-Z]`
    s_str=`echo $temp_pwd|cut -c2-`
    VERIDATA_PASSWORD=${f_str}${s_str}
    echo ""
    echo "    Weblogic Administrator password Auto Generated :"
    echo ""
    echo "    ----> Weblogic Administrator password: $VERIDATA_PASSWORD"
    echo ""
fi


if [ -z "${DATABASE_JDBC_URL}" ]
then
    CONNECTION_STRING="${DATABASE_HOST}:${DATABASE_PORT}/${DATABASE_SERVICE}"

else
    CONNECTION_STRING="${DATABASE_JDBC_URL}"
fi

JDBC_URL="jdbc:oracle:thin:@$CONNECTION_STRING"

if [ -z "${DATABASE_TYPE}" ]
then
    DATABASE_TYPE="ORACLE"
fi

if [ "${DATABASE_TYPE}" == "SQLSERVER" ]
then
  JDBC_URL="jdbc:weblogic:sqlserver://$CONNECTION_STRING"
else
  if [ "${DATABASE_TYPE}" == "MYSQL" ]
  then
    JDBC_URL="jdbc:mysql://$CONNECTION_STRING"
  fi
fi

export DATABASE_HOST=$DATABASE_HOST
export DATABASE_PORT=$DATABASE_PORT
export DATABASE_SERVICE=$DATABASE_SERVICE
export SCHEMA_PREFIX=$SCHEMA_PREFIX
export SCHEMA_PASSWORD=$SCHEMA_PASSWORD
export DATABASE_PASSWORD=$DATABASE_PASSWORD
export DATABASE_USER=$DATABASE_USER
export JDBC_URL=$JDBC_URL
export DATABASE_TYPE=$DATABASE_TYPE


if [ -z ${DATABASE_USER} ]
then
    export DATABASE_USER="sys"
fi

RUN_RCU="true"


if [ -d  $CONTAINERCONFIG_DIR ]
then
	# First load the Env Data from the env file...
	if [ -e $CONTAINERCONFIG_DIR/vdtserverenv.sh ]
	then
		.$CONTAINERCONFIG_DIR/vdtserverenv.sh
		#reset the JDBC URL
		if [ -n "${DATABASE_JDBC_URL}" ]
    	then
        	JDBC_URL="$DATABASE_JDBC_URL"
        fi
	fi
else
	mkdir -p $CONTAINERCONFIG_DIR
fi

echo "JDBC_URL=${JDBC_URL}"
echo "CONNECTION_STRING=${CONNECTION_STRING}"

export CONNECTION_STRING="${CONNECTION_STRING}"
export JDBC_URL="${JDBC_URL}"

if [ -e $CONTAINERCONFIG_DIR/RCU.suc ]
then
	#RCU has already been executed successfully, no need to rerun
	RUN_RCU="false"
	echo "OGG Veridata RCU has already been loaded.. skipping"
fi

echo "Loading RCU Phase"
echo "==================================="

if [ "${RUN_RCU}" == "true" ]
then

    VDT_COMPS="-component STB -component VERIDATA"
    OTHER_COMPS="-component IAU -component IAU_APPEND -component IAU_VIEWER -component OPSS -component MDS -component WLS"
    # Run the RCU.. it hasnt been loaded before..
    echo -e "$DATABASE_PASSWORD\n$SCHEMA_PASSWORD" | $ORACLE_HOME/oracle_common/bin/rcu -silent -createRepository -connectString $CONNECTION_STRING -databaseType $DATABASE_TYPE -dbUser $DATABASE_USER -dbRole sysdba -useSamePasswordForAllSchemaUsers true -schemaPrefix $SCHEMA_PREFIX $VDT_COMPS $OTHER_COMPS
    retval=$?

    if [ $retval -ne 0 ];
    then
    	echo "RCU Loading Failed.. Check the RCU logs"
    	exit
    else
    	# Write the rcu suc file...
    	touch $CONTAINERCONFIG_DIR/RCU.suc
    fi
fi

if [ -z "${ADMIN_NAME}" ]
    then
        ADMIN_NAME="AdminServer"
fi

if [ -z "${PROD_MODE}" ]
    then
        PROD_MODE="prod"
fi

export ADMIN_NAME="${ADMIN_NAME}"
export PROD_MODE="${PROD_MODE}"


# Create an Infrastructure domain
# set environments needed for the script to work

CONFIGURE_DOMAIN="true"

if [ -f ${DOMAIN_HOME}/servers/${ADMIN_NAME}/logs/${ADMIN_NAME}.log ];
then
    CONFIGURE_DOMAIN="false"
fi


echo "Installation of Veridata Domain"
echo "==================================="

if [ "${CONFIGURE_DOMAIN}" == "true" ]
then
	echo "Running WLST.. "
    $ORACLE_HOME/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning $ORACLE_HOME/container-scripts/createVeridataDomain.py -oh $ORACLE_HOME -jh $JAVA_HOME -dh $DOMAIN_HOME -name $VERIDATA_DOMAIN_NAME -port $VERIDATA_PORT -user $VERIDATA_USER -password $VERIDATA_PASSWORD -rcuDb $JDBC_URL -rcuPrefix $SCHEMA_PREFIX -rcuSchemaPwd $SCHEMA_PASSWORD -adminPort $ADMIN_PORT -adminName $ADMIN_NAME -prodMode $PROD_MODE
	retval=$?
	if [ $retval -ne 0 ]
	then
	   	echo "Domain Configuration failed.. please check the logs for errors"
	   	exit
	else
	   	# Write the Domain suc file...
	   	touch $CONTAINERCONFIG_DIR/VDT.Domain.Configure.suc
        echo "$ORACLE_HOME/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning $ORACLE_HOME/container-scripts/createVeridataDomain.py -oh $ORACLE_HOME -jh $JAVA_HOME -dh $DOMAIN_HOME -name $VERIDATA_DOMAIN_NAME -port $VERIDATA_PORT -user $VERIDATA_USER -password $VERIDATA_PASSWORD -rcuDb $JDBC_URL -rcuPrefix $SCHEMA_PREFIX -rcuSchemaPwd $SCHEMA_PASSWORD -adminPort $ADMIN_PORT -adminName $ADMIN_NAME -prodMode $PROD_MODE">> $CONTAINERCONFIG_DIR/VDT.Domain.Configure.suc
	    echo "DATABASE_JDBC_URL=$JDBC_URL" > $CONTAINERCONFIG_DIR/vdtserverenv.sh
	    echo "CONNECTION_STRING=$CONNECTION_STRING" > $CONTAINERCONFIG_DIR/vdtserverenv.sh
	   	echo "SCHEMA_PREFIX=$SCHEMA_PREFIX" >> $CONTAINERCONFIG_DIR/vdtserverenv.sh
	   	echo "SCHEMA_PASSWORD=$SCHEMA_PASSWORD" >> $CONTAINERCONFIG_DIR/vdtserverenv.sh

	   	# Create the security file to start the server(s) without the password prompt
        mkdir -p ${DOMAIN_HOME}/servers/${ADMIN_NAME}/security/
        echo "username=${VERIDATA_USER}" >> ${DOMAIN_HOME}/servers/${ADMIN_NAME}/security/boot.properties
        echo "password=${VERIDATA_PASSWORD}" >> ${DOMAIN_HOME}/servers/${ADMIN_NAME}/security/boot.properties


      # Setting env variables
      #=======================
      echo ".${DOMAIN_HOME}/bin/setDomainEnv.sh" >> ${DOMAIN_HOME}/.bashrc
      echo "export PATH=$PATH:${ORACLE_HOME}/common/bin:${DOMAIN_HOME}/bin" >> $ORACLE_HOME/.bashrc
	fi
fi

#Set Java options
export JAVA_OPTIONS=${JAVA_OPTIONS}
echo "Java Options: ${JAVA_OPTIONS}"

echo "Starting the Admin Server"
echo "=========================="

${DOMAIN_HOME}/bin/setDomainEnv.sh

# Start Admin Server and tail the logs
${DOMAIN_HOME}/startWebLogic.sh
tail -f ${DOMAIN_HOME}/servers/${ADMIN_NAME}/logs/${ADMIN_NAME}.log
childPID=$!
wait $childPID

#sleep 5d
