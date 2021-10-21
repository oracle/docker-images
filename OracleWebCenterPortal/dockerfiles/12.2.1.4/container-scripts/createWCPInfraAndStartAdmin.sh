#!/bin/bash
# Copyright (c)  2020,2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
function validate_parameter {
  name=$1
  value=$2
  if [ -z $value ]
  then
    echo "ERROR: Please set '$name' in the environment file (webcenter.env.list)."
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

# validate ADMIN_SERVER_CONTAINER_NAME
validate_parameter "ADMIN_SERVER_CONTAINER_NAME" $ADMIN_SERVER_CONTAINER_NAME

# validate DOMAIN_NAME
validate_parameter "DOMAIN_NAME" $DOMAIN_NAME

# validate ADMIN_PORT
validate_parameter "ADMIN_PORT" $ADMIN_PORT

# validate ADMIN_USERNAME
validate_parameter "ADMIN_USERNAME" $ADMIN_USERNAME

# validate ADMIN_PASSWORD
validate_parameter "ADMIN_PASSWORD" $ADMIN_PASSWORD

# validate MANAGED_SERVER_PORT
validate_parameter "MANAGED_SERVER_PORT" $MANAGED_SERVER_PORT

echo "Environment variables"
echo "====================="
echo ""
echo "DB_DROP_AND_CREATE=${DB_DROP_AND_CREATE}"
echo "DB_CONNECTION_STRING=${DB_CONNECTION_STRING}"
echo "DB_RCUPREFIX=${DB_RCUPREFIX}"
echo "ADMIN_SERVER_CONTAINER_NAME=${ADMIN_SERVER_CONTAINER_NAME}"
echo "DOMAIN_NAME=${DOMAIN_NAME}"
echo "ADMIN_PORT=${ADMIN_PORT}"
echo "ADMIN_USERNAME=${ADMIN_USERNAME}"
echo "MANAGED_SERVER_PORT=${MANAGED_SERVER_PORT}"
echo "KEEP_CONTAINER_ALIVE=${KEEP_CONTAINER_ALIVE}"
echo "MANAGED_SERVER_PORTLET_PORT=${MANAGED_SERVER_PORTLET_PORT}"
echo ""
echo ""

export DROP_SCHEMA=$DB_DROP_AND_CREATE
export CONNECTION_STRING=$DB_CONNECTION_STRING
export RCUPREFIX=$DB_RCUPREFIX
export ADMIN_PASSWORD=$ADMIN_PASSWORD
export ADMIN_HOSTNAME=$ADMIN_HOSTNAME
export ADMIN_USERNAME=$ADMIN_USERNAME
export ADMIN_PORT=$ADMIN_PORT
export DOMAIN_NAME='wcp-domain'
export DB_PASSWORD=$DB_PASSWORD
export DB_SCHEMA_PASSWORD=$DB_SCHEMA_PASSWORD
export MANAGED_SERVER_PORT=${MANAGED_SERVER_PORT}
export MANAGED_SERVER_PORTLET_PORT=${MANAGED_SERVER_PORTLET_PORT}
export jdbc_url="jdbc:oracle:thin:@"$CONNECTION_STRING
export vol_name=u01
export KEEP_CONTAINER_ALIVE=$KEEP_CONTAINER_ALIVE
echo -e $DB_PASSWORD"\n"$DB_SCHEMA_PASSWORD > /$vol_name/oracle/pwd.txt

CONTAINERCONFIG_DIR_NAME="container-data"
CONTAINERCONFIG_DIR="/$vol_name/oracle/user_projects/$CONTAINERCONFIG_DIR_NAME"
CONTAINERCONFIG_LOG_DIR="$CONTAINERCONFIG_DIR/logs"

#============================================
# Creating schemas needed for WCPortal domain
#============================================

RUN_RCU="true"
CONFIGURE_DOMAIN="true"

if [ -d  $CONTAINERCONFIG_DIR ] 
then
  #First load the Env Data from the env file... 
  if [ -e $CONTAINERCONFIG_DIR/contenv.sh ] 
  then
    sh /$CONTAINERCONFIG_DIR/contenv.sh
    #reset the JDBC URL
    export jdbc_url="jdbc:oracle:thin:@"$CONNECTION_STRING
  fi
fi

if [ -e $CONTAINERCONFIG_DIR/RCU.$RCUPREFIX.suc ] 
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
  echo "WebCenter Portal RCU Creation Phase"
  echo "==================================="
  echo ""
  echo ""

  if [ "$DROP_SCHEMA" == "true" ]
  then
    export RCU_LOG_NAME="RCU_dropRepository.out"
    /$vol_name/oracle/oracle_common/bin/rcu -silent -dropRepository -databaseType ORACLE -connectString $CONNECTION_STRING -dbUser sys -dbRole SYSDBA -schemaPrefix $RCUPREFIX -component STB -component OPSS -component IAU -component IAU_APPEND -component IAU_VIEWER -component MDS -component WEBCENTER -component WLS -component PORTLET -component ACTIVITIES -f < /$vol_name/oracle/pwd.txt
    retval=$?
    if [ $retval -ne 0 ];
    then
      echo ""   
      echo ""   
      echo "RCU drop repository failed. Please check the RCU log : $CONTAINERCONFIG_LOG_DIR/RCU_dropRepository.out"
      echo "Ignoring this operation and proceeding with RCU create."
    fi
  fi

  # Run the RCU.. it hasn't been loaded before.. 	
  export RCU_LOG_NAME="RCU_createRepository.out"
  /$vol_name/oracle/oracle_common/bin/rcu -silent -createRepository -databaseType ORACLE -connectString $CONNECTION_STRING -dbUser sys -dbRole SYSDBA -useSamePasswordForAllSchemaUsers true -selectDependentsForComponents true -schemaPrefix $RCUPREFIX -component OPSS -component IAU_VIEWER -component WEBCENTER -component MDS -component IAU_APPEND -component STB -component IAU -component WLS -component PORTLET -component ACTIVITIES -tablespace USERS -tempTablespace TEMP -f < /$vol_name/oracle/pwd.txt
  retval=$?
  if [ $retval -ne 0 ];
  then
    echo ""   
    echo ""   
    echo "RCU create repository failed. Please check the RCU log : $CONTAINERCONFIG_LOG_DIR/RCU_createRepository.out"
    exit 1
  else
    # Write the rcu suc file... 
    touch $CONTAINERCONFIG_DIR/RCU.$RCUPREFIX.suc
    echo "/$vol_name/oracle/oracle_common/bin/rcu -silent -createRepository -databaseType ORACLE -connectString $CONNECTION_STRING -dbUser sys -dbRole SYSDBA -useSamePasswordForAllSchemaUsers true -selectDependentsForComponents true -schemaPrefix $RCUPREFIX -component OPSS -component IAU_VIEWER -component WEBCENTER -component MDS -component IAU_APPEND -component STB -component IAU -component WLS -tablespace USERS -tempTablespace TEMP -f < /$vol_name/oracle/pwd.txt" >> $CONTAINERCONFIG_DIR/RCU.$RCUPREFIX.suc
  fi
fi

#==============
# Get Host Name
#==============
export hostname=`hostname -I`

#=================================
# Configuration of WCPortal domain
#=================================
if [ -e $CONTAINERCONFIG_DIR/WCPortal.Domain.Configure.suc ] 
then
  CONFIGURE_DOMAIN="false"
fi

if [ "$CONFIGURE_DOMAIN" == "true" ] 
then
  echo ""
  echo "Domain Configuration Phase"
  echo "=========================="

  /$vol_name/oracle/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning /$vol_name/oracle/container-scripts/createWebCenterPortalDomain.py -oh $ORACLE_HOME -jh $JAVA_HOME -parent /$vol_name/oracle/user_projects/domains -name $DOMAIN_NAME -user $ADMIN_USERNAME -password $ADMIN_PASSWORD -rcuDb $CONNECTION_STRING -rcuPrefix $RCUPREFIX -rcuSchemaPwd $DB_SCHEMA_PASSWORD -adminServerPort $ADMIN_PORT -managedServerPort $MANAGED_SERVER_PORT -managedServerPortletPort $MANAGED_SERVER_PORTLET_PORT
  retval=$?
  if [ $retval -ne 0 ]; 
  then
    echo "Domain configuration failed... please check the logs for errors"
    exit 1
  else
    # Write the domain suc file... 
    touch $CONTAINERCONFIG_DIR/WCPortal.Domain.Configure.suc
    touch $CONTAINERCONFIG_DIR/contenv.sh 
    chmod 755 $CONTAINERCONFIG_DIR/contenv.sh

    echo "/$vol_name/oracle/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning /$vol_name/oracle/createWebCenterPortalDomain.py -oh $ORACLE_HOME -jh $JAVA_HOME -parent /$vol_name/oracle/user_projects/domains -name $DOMAIN_NAME -user $ADMIN_USERNAME -password $ADMIN_PASSWORD -rcuDb $CONNECTION_STRING -rcuPrefix $RCUPREFIX -rcuSchemaPwd $DB_SCHEMA_PASSWORD -adminServerPort $ADMIN_PORT -managedServerPort $MANAGED_SERVER_PORT -managedServerPortletPort $MANAGED_SERVER_PORTLET_PORT" >> $CONTAINERCONFIG_DIR/WCPortal.Domain.Configure.suc
  
    echo "CONNECTION_STRING=$CONNECTION_STRING" > $CONTAINERCONFIG_DIR/contenv.sh
    echo "RCUPREFIX=$RCUPREFIX" >> $CONTAINERCONFIG_DIR/contenv.sh
    echo "ADMIN_USERNAME=$ADMIN_USERNAME" >> $CONTAINERCONFIG_DIR/contenv.sh
    echo "ADMIN_PASSWORD=$ADMIN_PASSWORD" >> $CONTAINERCONFIG_DIR/contenv.sh
    echo "DB_PASSWORD=$DB_PASSWORD" >> $CONTAINERCONFIG_DIR/contenv.sh
    echo "KEEP_CONTAINER_ALIVE=$KEEP_CONTAINER_ALIVE" >> $CONTAINERCONFIG_DIR/contenv.sh
    echo "vol_name=$vol_name" >> $CONTAINERCONFIG_DIR/contenv.sh
  fi

  # Creating domain env file
  mkdir -p /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/servers/AdminServer/security
  mkdir -p /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/servers/WC_Portal/security
  mkdir -p /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/servers/WC_Portlet/security
  mv /$vol_name/oracle/container-scripts/commEnv.sh /$vol_name/oracle/wlserver/common/bin/commEnv.sh

  # Password less Adminserver starting
  echo "username="$ADMIN_USERNAME > /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/servers/AdminServer/security/boot.properties
  echo "password="$ADMIN_PASSWORD >> /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/servers/AdminServer/security/boot.properties

  # Password less WCPortal server starting
  echo "username="$ADMIN_USERNAME > /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/servers/WC_Portal/security/boot.properties
  echo "password="$ADMIN_PASSWORD >> /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/servers/WC_Portal/security/boot.properties

  # Password less WCPortlet server starting
  echo "username="$ADMIN_USERNAME > /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/servers/WC_Portlet/security/boot.properties
  echo "password="$ADMIN_PASSWORD >> /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/servers/WC_Portlet/security/boot.properties
fi

# delete password file
rm -f /$vol_name/oracle/pwd.txt

# Setting env variables
echo ". /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin/setDomainEnv.sh" >> /$vol_name/oracle/.bashrc
echo "export PATH=$PATH:/$vol_name/oracle/common/bin:/$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin" >> /$vol_name/oracle/.bashrc

# setting user override 
cp /$vol_name/oracle/container-scripts/setUserOverrides.sh /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin/

echo ""
echo "Starting Node Manager"
echo "====================="
echo ""
echo "tail /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin/nodemanager.out in a new window"
echo ""

cd /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin
./startNodeManager.sh > nodemanager.out 2>&1&
sleep 10

# Now we start the Admin server in this container... 
sh /$vol_name/oracle/container-scripts/startAdmin.sh

if [ "$CONFIGURE_DOMAIN" == "true" ]
then
  echo "Assigning machines and clusters to the managed servers"
  echo "======================================================"
  echo ""
  # Configure Node Manager
  /$vol_name/oracle/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning /$vol_name/oracle/container-scripts/configureNodeManager.py $hostname $vol_name

  # Restart admin server
  sh /$vol_name/oracle/container-scripts/stopAdmin.sh
  sleep 10
  sh /$vol_name/oracle/container-scripts/startAdmin.sh
fi

cd /$vol_name/oracle/

echo ""
echo ""
if [ "$KEEP_CONTAINER_ALIVE" == "true" ]
then
  # This keeps the container running and alive
  export ADMIN_SERVER_NAME=AdminServer
  sh /$vol_name/oracle/container-scripts/keepContainerAlive.sh $CONTAINERCONFIG_LOG_DIR $hostname $ADMIN_SERVER_NAME
fi
