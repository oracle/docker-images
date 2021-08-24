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
validate_parameter "IPM_PORT" $IPM_PORT


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
echo "IPM_PORT=${IPM_PORT}"
echo "ADMIN_USERNAME=${ADMIN_USERNAME}"
echo "ADMIN_PASSWORD=${ADMIN_PASSWORD}"
echo "KEEP_CONTAINER_ALIVE=${KEEP_CONTAINER_ALIVE}"
echo ""
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

export IPM_PORT=$IPM_PORT
export KEEP_CONTAINER_ALIVE=$KEEP_CONTAINER_ALIVE
echo -e $DB_PASSWORD"\n"$DB_SCHEMA_PASSWORD > /$vol_name/oracle/pwd.txt

CONTAINERCONFIG_DIR_NAME="container-data"
CONTAINERCONFIG_DIR="/$vol_name/oracle/user_projects/$CONTAINERCONFIG_DIR_NAME"
CONTAINERCONFIG_LOG_DIR="$CONTAINERCONFIG_DIR/logs"

#============================================
# Creating schemas needed for Imaging domain
#============================================

RUN_RCU="true"
CONFIGURE_DOMAIN="true"

if [ -d  $CONTAINERCONFIG_DIR ] 
then
  #First load the Env Data from the env file... 
  if [ -e $CONTAINERCONFIG_DIR/ipmenv.sh ] 
  then
    sh /$CONTAINERCONFIG_DIR/ipmenv.sh
    #reset the JDBC URL
    export jdbc_url="jdbc:oracle:thin:@"$CONNECTION_STRING
  fi
fi

if [ -e $CONTAINERCONFIG_DIR/RCU_IPM.$RCUPREFIX.suc ] 
then
  # RCU has already been executed successfully, no need to rerun
  RUN_RCU="false"
fi

if [ "$RUN_RCU" == "true" ] 
then
  export RCU_LOG_LOCATION=$CONTAINERCONFIG_DIR
  export RCU_TIMESTAMP_LOG_DIR="false"
  export RCU_LOG_LEVEL="ERROR" 
  echo ""   
  echo "WebCenter Imaging RCU Creation Phase"
  echo "===================================="
  echo ""

  
  if [ "$DROP_SCHEMA" == "true" ]
  then
    export RCU_LOG_NAME="RCU_IPM_dropRepository.out"
    /$vol_name/oracle/oracle_common/bin/rcu -silent -dropRepository -databaseType ORACLE -connectString $CONNECTION_STRING -dbUser sys -dbRole SYSDBA -schemaPrefix $RCUPREFIX -component IPM -f < /$vol_name/oracle/pwd.txt
    retval=$?
    if [ $retval -ne 0 ];
    then
      echo ""   
      echo ""   
      echo "RCU IPM drop repository failed. Please check the RCU log : $CONTAINERCONFIG_LOG_DIR/RCU_IPM_dropRepository.out"
      echo "Ignoring this operation and proceeding with RCU create."
    fi
  fi

  # Run the IPM RCU.. it hasn't been loaded before.. 	
  export RCU_LOG_NAME="RCU_IPM_createRepository.out"
  /$vol_name/oracle/oracle_common/bin/rcu -silent -createRepository -databaseType ORACLE -connectString $CONNECTION_STRING -dbUser sys -dbRole SYSDBA -useSamePasswordForAllSchemaUsers true -schemaPrefix $RCUPREFIX -component IPM  -tablespace USERS -tempTablespace TEMP -f < /$vol_name/oracle/pwd.txt 
  retval=$?
  if [ $retval -ne 0 ];
  then
    echo ""   
    echo ""   
    echo "RCU IPM create repository failed. Please check the RCU log : $CONTAINERCONFIG_LOG_DIR/RCU_IPM_createRepository.out"
    exit 1
  else
    # Write the rcu suc file... 
    touch $CONTAINERCONFIG_DIR/RCU_IPM.$RCUPREFIX.suc
    echo "/$vol_name/oracle/oracle_common/bin/rcu -silent -createRepository -databaseType ORACLE -connectString $CONNECTION_STRING -dbUser sys -dbRole SYSDBA -useSamePasswordForAllSchemaUsers true -schemaPrefix $RCUPREFIX -component IPM -tablespace USERS -tempTablespace TEMP -f < /$vol_name/oracle/pwd.txt" >> $CONTAINERCONFIG_DIR/RCU_IPM.$RCUPREFIX.suc
  fi
fi

#==============
# Get Host Name
#==============
export hostname=$HOSTNAME

#=================================
# Configuration of IPM domain
#=================================
if [ -e $CONTAINERCONFIG_DIR/IPM.Domain.Configure.suc ] 
then
  CONFIGURE_DOMAIN="false"
fi

if [ "$CONFIGURE_DOMAIN" == "true" ] 
then
  echo ""
  echo "IPM Domain Configuration Phase"
  echo "=============================="

  /$vol_name/oracle/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning /$vol_name/oracle/container-scripts/createIPMDomain_PS4.py -oh $ORACLE_HOME -jh $JAVA_HOME -parent /$vol_name/oracle/user_projects/domains -name $DOMAIN_NAME -user $ADMIN_USERNAME  -password $ADMIN_PASSWORD -rcuDb $CONNECTION_STRING -rcuPrefix $RCUPREFIX -rcuSchemaPwd $DB_SCHEMA_PASSWORD -adminServerPort $ADMIN_PORT -ipmManagedServerPort $IPM_PORT 
  retval=$?
  if [ $retval -ne 0 ]; 
  then
    echo "IPM Domain configuration failed... please check the logs for errors"
    exit 1
  else
    # Write the domain suc file... 
    touch $CONTAINERCONFIG_DIR/IPM.Domain.Configure.suc
    touch $CONTAINERCONFIG_DIR/ipmenv.sh 
    chmod 755 $CONTAINERCONFIG_DIR/ipmenv.sh

    echo "/$vol_name/oracle/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning /$vol_name/oracle/createIPMDomain_PS4.py -oh $ORACLE_HOME -jh $JAVA_HOME -parent /$vol_name/oracle/user_projects/domains -name $DOMAIN_NAME -password $ADMIN_PASSWORD -rcuDb $CONNECTION_STRING -rcuPrefix $RCUPREFIX -rcuSchemaPwd $DB_SCHEMA_PASSWORD -adminServerPort $ADMIN_PORT -ipmManagedServerPort $IPM_PORT" >> $CONTAINERCONFIG_DIR/IPM.Domain.Configure.suc
  
    echo "CONNECTION_STRING=$CONNECTION_STRING" > $CONTAINERCONFIG_DIR/ipmenv.sh
    echo "RCUPREFIX=$RCUPREFIX" >> $CONTAINERCONFIG_DIR/ipmenv.sh
    echo "ADMIN_PASSWORD=$ADMIN_PASSWORD" >> $CONTAINERCONFIG_DIR/ipmenv.sh
    echo "DB_PASSWORD=$DB_PASSWORD" >> $CONTAINERCONFIG_DIR/ipmenv.sh
    echo "KEEP_CONTAINER_ALIVEi=$KEEP_CONTAINER_ALIVE" >> $CONTAINERCONFIG_DIR/ipmenv.sh
    echo "vol_name=$vol_name" >> $CONTAINERCONFIG_DIR/ipmenv.sh
  fi

  # Creating IPM server security folder.
  mkdir -p /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/servers/IPM_server1/security
  
  # Password less IPM  server starting
  echo "username="$ADMIN_USERNAME > /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/servers/IPM_server1/security/boot.properties
  echo "password="$ADMIN_PASSWORD >> /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/servers/IPM_server1/security/boot.properties
fi 

# delete password file
rm -f /$vol_name/oracle/pwd.txt


