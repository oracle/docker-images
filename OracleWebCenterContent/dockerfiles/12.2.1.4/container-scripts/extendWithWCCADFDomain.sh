#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
#

function validate_parameter {
  name=$1
  value=$2
  if [ -z $value ]
  then
    echo "ERROR: Please set '$name' in configmap[webcenter.env.list file]."
    echo ""       
    exit 1
  fi
}

if [ -z "$DB_DROP_AND_CREATE" ]
then
  export DB_DROP_AND_CREATE="false"  
fi

if [ -z ${KEEP_CONTAINER_ALIVE} ]
then
   # by default we always keep this flag ON
   export KEEP_CONTAINER_ALIVE="true"
fi

# validate DB_CONNECTION_STRING
validate_parameter "DB_CONNECTION_STRING" $DB_CONNECTION_STRING

# validate DB_RCUPREFIX
validate_parameter "DB_RCUPREFIX" $DB_RCUPREFIX

# validate DB_PASSWORD
validate_parameter "DB_PASSWORD" $DB_PASSWORD

# validate DB_SCHEMA_PASSWORD
validate_parameter "DB_SCHEMA_PASSWORD" $DB_SCHEMA_PASSWORD

# validate HOSTNAME
validate_parameter "HOSTNAME" $HOSTNAME

# validate ADMIN_SERVER_CONTAINER_NAME
validate_parameter "ADMIN_SERVER_CONTAINER_NAME" $ADMIN_SERVER_CONTAINER_NAME

# validate ADMIN_PORT
validate_parameter "ADMIN_PORT" $ADMIN_PORT

# validate ADMIN_USERNAME
validate_parameter "ADMIN_USERNAME" $ADMIN_USERNAME

# validate ADMIN_PASSWORD
validate_parameter "ADMIN_PASSWORD" $ADMIN_PASSWORD

validate_parameter "DOMAIN_NAME" $DOMAIN_NAME
validate_parameter "WCCADF_PORT" $WCCADF_PORT


echo "Environment variables"
echo "====================="
echo ""
echo "DB_DROP_AND_CREATE=${DB_DROP_AND_CREATE}"
echo "DB_CONNECTION_STRING=${DB_CONNECTION_STRING}"
echo "DB_RCUPREFIX=${DB_RCUPREFIX}"
echo "DB_PASSWORD=${DB_PASSWORD}"
echo "DB_SCHEMA_PASSWORD=${DB_SCHEMA_PASSWORD}"
echo "HOSTNAME=${HOSTNAME}"
echo "ADMIN_SERVER_CONTAINER_NAME=${ADMIN_SERVER_CONTAINER_NAME}"
echo "DOMAIN_NAME=${DOMAIN_NAME}"
echo "ADMIN_PORT=${ADMIN_PORT}"
echo "WCCADF_PORT=${WCCADF_PORT}"
echo "ADMIN_USERNAME=${ADMIN_USERNAME}"
echo "ADMIN_PASSWORD=${ADMIN_PASSWORD}"
echo "KEEP_CONTAINER_ALIVE=${KEEP_CONTAINER_ALIVE}"
echo "UCM_INTRADOC_PORT=${UCM_INTRADOC_PORT}"
echo ""

export DROP_SCHEMA=$DB_DROP_AND_CREATE
export CONNECTION_STRING=$DB_CONNECTION_STRING
export RCUPREFIX=$DB_RCUPREFIX
export ADMIN_PASSWORD=$ADMIN_PASSWORD
export HOSTNAME=$HOSTNAME
export DOMAIN_NAME=$DOMAIN_NAME
export ADMIN_USERNAME=$ADMIN_USERNAME
export ADMIN_PORT=$ADMIN_PORT
export DB_PASSWORD=$DB_PASSWORD
export DB_SCHEMA_PASSWORD=$DB_SCHEMA_PASSWORD
export jdbc_url="jdbc:oracle:thin:@"$CONNECTION_STRING
export vol_name=u01
export UCM_INTRADOC_PORT=$UCM_INTRADOC_PORT

export WCCADF_PORT=$WCCADF_PORT
export KEEP_CONTAINER_ALIVE=$KEEP_CONTAINER_ALIVE
echo -e $DB_PASSWORD"\n"$DB_SCHEMA_PASSWORD > /$vol_name/oracle/pwd.txt

CONTAINERCONFIG_DIR_NAME="container-data"
CONTAINERCONFIG_DIR="/$vol_name/oracle/user_projects/$CONTAINERCONFIG_DIR_NAME"
CONTAINERCONFIG_LOG_DIR="$CONTAINERCONFIG_DIR/logs"

RUN_RCU="false"
CONFIGURE_DOMAIN="true"

if [ -d  $CONTAINERCONFIG_DIR ] 
then
  #First load the Env Data from the env file... 
  if [ -e $CONTAINERCONFIG_DIR/wccadfenv.sh ] 
  then
    sh /$CONTAINERCONFIG_DIR/wccadfenv.sh
    #reset the JDBC URL
    export jdbc_url="jdbc:oracle:thin:@"$CONNECTION_STRING
  fi
fi


#==============
# Get Host Name
#==============
export hostname=$HOSTNAME

#=================================
# Configuration of WCCADF domain
#=================================
if [ -e $CONTAINERCONFIG_DIR/WCCADF.Domain.Configure.suc ] 
then
  CONFIGURE_DOMAIN="false"
fi

if [ "$CONFIGURE_DOMAIN" == "true" ] 
then
  echo ""
  echo "WCCADF Domain Configuration Phase"
  echo "=============================="

  /$vol_name/oracle/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning /$vol_name/oracle/container-scripts/createWCCADFDomain_PS4.py -oh $ORACLE_HOME -jh $JAVA_HOME -parent /$vol_name/oracle/user_projects/domains -name $DOMAIN_NAME -user $ADMIN_USERNAME  -password $ADMIN_PASSWORD -rcuDb $CONNECTION_STRING -rcuPrefix $RCUPREFIX -rcuSchemaPwd $DB_SCHEMA_PASSWORD -adminServerPort $ADMIN_PORT -wccadfManagedServerPort $WCCADF_PORT 
  retval=$?
  if [ $retval -ne 0 ]; 
  then
    echo "WCCADF Domain configuration failed... please check the logs for errors"
    exit 1
  else
    # Write the domain suc file... 
    touch $CONTAINERCONFIG_DIR/WCCADF.Domain.Configure.suc
    touch $CONTAINERCONFIG_DIR/wccadfenv.sh 
    chmod 755 $CONTAINERCONFIG_DIR/wccadfenv.sh

    echo "/$vol_name/oracle/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning /$vol_name/oracle/createWCCADFDomain_PS4.py -oh $ORACLE_HOME -jh $JAVA_HOME -parent /$vol_name/oracle/user_projects/domains -name $DOMAIN_NAME -password $ADMIN_PASSWORD -rcuDb $CONNECTION_STRING -rcuPrefix $RCUPREFIX -rcuSchemaPwd $DB_SCHEMA_PASSWORD -adminServerPort $ADMIN_PORT -wccadfManagedServerPort $WCCADF_PORT" >> $CONTAINERCONFIG_DIR/WCCADF.Domain.Configure.suc
  
    echo "CONNECTION_STRING=$CONNECTION_STRING" > $CONTAINERCONFIG_DIR/wccadfenv.sh
    echo "RCUPREFIX=$RCUPREFIX" >> $CONTAINERCONFIG_DIR/wccadfenv.sh
    echo "ADMIN_PASSWORD=$ADMIN_PASSWORD" >> $CONTAINERCONFIG_DIR/wccadfenv.sh
    echo "DB_PASSWORD=$DB_PASSWORD" >> $CONTAINERCONFIG_DIR/wccadfenv.sh
    echo "KEEP_CONTAINER_ALIVEi=$KEEP_CONTAINER_ALIVE" >> $CONTAINERCONFIG_DIR/wccadfenv.sh
    echo "vol_name=$vol_name" >> $CONTAINERCONFIG_DIR/wccadfenv.sh
  fi

  # Creating WCCADF server security folder.
  mkdir -p /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/servers/WCCADF_server1/security
  
  # Password less WCCADF  server starting
  echo "username="$ADMIN_USERNAME > /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/servers/WCCADF_server1/security/boot.properties
  echo "password="$ADMIN_PASSWORD >> /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/servers/WCCADF_server1/security/boot.properties
  
fi 

# delete password file
rm -f /$vol_name/oracle/pwd.txt


