#!/bin/bash
# Copyright (c) 2020, 2022, Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Author: OIG Development
#

export DOMAIN_HOME=$DOMAIN_ROOT/$DOMAIN_NAME

########### SIGINT handler ############
function _int() {
  echo "INFO: Stopping container."
  echo "INFO:   SIGINT received, shutting down Admin Server!"
  /u01/oracle/user_projects/domains/base_domain/bin/stopWebLogic.sh
  exit;
}

########### SIGTERM handler ############
function _term() {
  echo "INFO: Stopping container."
  echo "INFO:   SIGTERM received, shutting down Admin Server!"
  /u01/oracle/user_projects/domains/base_domain/bin/stopWebLogic.sh
  exit;
}

########### SIGKILL handler ############
function _kill() {
  echo "INFO: SIGKILL received, shutting down Admin Server!"
  /u01/oracle/user_projects/domains/base_domain/bin/stopWebLogic.sh
  exit;
}

#######Random Password Generation########
function rand_pwd(){
  while true; do
    s=$(cat /dev/urandom | tr -dc "A-Za-z0-9" | fold -w 8 | head -n 1)
    if [[ ${#s} -ge 8 && "$s" == *[A-Z]* && "$s" == *[a-z]* && "$s" == *[0-9]*  ]]
    then
      break
    else
      echo "INFO: Password does not Match the criteria, re-generating..." >&2
    fi
  done
  echo "${s}"
}

#==================================================↲
function updateListenAddress() {
  mkdir -p ${DOMAIN_HOME}/logs

  export thehost=`hostname -I`
  echo "INFO: Updating the listen address of Adminserver -> IP->${thehost} DNS->${ADMIN_HOST}"
  cmd1="${ORACLE_HOME}/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning ${SCRIPT_DIR}/updateListenAddress.py ${thehost} AdminServer ${ADMIN_HOST}"
  echo ${cmd1}
  echo "${cmd1}" > ${DOMAIN_HOME}/logs/aslisten.log
  ${cmd1} >> ${DOMAIN_HOME}/logs/aslisten.log 2>&1
 }

# Set SIGINT handler
trap _int SIGINT

# Set SIGTERM handler
trap _term SIGTERM

# Set SIGKILL handler
trap _kill SIGKILL

echo "INFO: CONNECTION_STRING = ${CONNECTION_STRING:?"Please set CONNECTION_STRING"}"
echo "INFO: RCUPREFIX         = ${RCUPREFIX:?"Please set RCUPREFIX"}"

if [ -z ${ADMIN_PASSWORD} ]
then
  # Auto generate Oracle WebLogic Server admin password
  ADMIN_PASSWORD=$(rand_pwd)
  echo ""
  echo "INFO: Oracle WebLogic Server Password Auto Generated :"
  echo "  'weblogic' admin password: $ADMIN_PASSWORD"
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
  echo "INFO: Database Schema password Auto Generated :"
  echo "  Database schema password: $DB_SCHEMA_PASSWORD"
  echo ""
fi

export CONNECTION_STRING=$CONNECTION_STRING
export RCUPREFIX=$RCUPREFIX
export ADMIN_PASSWORD=$ADMIN_PASSWORD
export DB_PASSWORD=$DB_PASSWORD
export DB_SCHEMA_PASSWORD=$DB_SCHEMA_PASSWORD
export DOMAIN_TYPE=$DOMAIN_TYPE
export SCRIPT_DIR=${SCRIPT_DIR:-/u01/oracle/dockertools}

export jdbc_url="jdbc:oracle:thin:@"$CONNECTION_STRING
export vol_name=u01

export DOMAIN_ROOT=$DOMAIN_ROOT
echo -e $DB_PASSWORD"\n"$DB_SCHEMA_PASSWORD > /tmp/pwd.txt

CTR_DIR=/$vol_name/oracle/user_projects/container

#
# Creating schemas needed for sample domain ####
#===============================================
#
RUN_RCU="true"
CONFIGURE_DOMAIN="true"

if [ -d  $CTR_DIR ]
then
  # First load the Env Data from the env file...
  if [ -e $CTR_DIR/contenv.sh ]
  then
    . $CTR_DIR/contenv.sh
    #reset the JDBC URL
    export jdbc_url="jdbc:oracle:thin:@"$CONNECTION_STRING
  fi
else
  mkdir $CTR_DIR
fi

if [ -e $CTR_DIR/RCU.$RCUPREFIX.suc ]
then
    #RCU has already been executed successfully, no need to rerun
    RUN_RCU="false"
    echo "INFO: OIM RCU has already been loaded. Skipping..."
fi

if [ "$RUN_RCU" = "true" ]
then

  # Before running RCU, OIM prerequisite script needs to be run.
  javac -cp $vol_name/oracle/oracle_common/modules/oracle.jdbc/ojdbc8.jar ${SCRIPT_DIR}/DBUtils.java -d /$vol_name/oracle/dockertools/
  java -cp /$vol_name/oracle/dockertools/:/$vol_name/oracle/oracle_common/modules/oracle.jdbc/ojdbc8.jar DBUtils $jdbc_url sys $DB_PASSWORD file /$vol_name/oracle/dockertools/xaview.sql

  # Run the RCU.. it hasnt been loaded before..
  /$vol_name/oracle/oracle_common/bin/rcu -silent -createRepository -databaseType ORACLE -connectString $CONNECTION_STRING -dbUser sys -dbRole sysdba -useSamePasswordForAllSchemaUsers true -selectDependentsForComponents true -schemaPrefix $RCUPREFIX -component OIM  -component MDS -component SOAINFRA -component OPSS -f < /tmp/pwd.txt
  retval=$?

  if [ $retval -ne 0 ];
  then
    echo "ERROR: RCU Loading Failed. Check the RCU logs"
    exit
  else
    # Write the rcu suc file...
    touch $CTR_DIR/RCU.$RCUPREFIX.suc

    # Write the env file.. such that the passwords etc.. will be saved and we will
    # be able to restart from the RCU
    cat > $CTR_DIR/contenv.sh <<EOF
CONNECTION_STRING=$CONNECTION_STRING
RCUPREFIX=$RCUPREFIX
ADMIN_PASSWORD=$ADMIN_PASSWORD
DB_PASSWORD=$DB_PASSWORD
DB_SCHEMA_PASSWORD=$DB_SCHEMA_PASSWORD
vol_name=$vol_name
EOF
  fi
fi

rm -f "/tmp/pwd.txt"

#
# Configuration of OIM domain
#=============================
if [ -e $CTR_DIR/OIM.DOMAINCFG.suc ]
then
  CONFIGURE_DOMAIN="false"
  echo "INFO: Domain Already configured. Skipping..."
fi

if [ "$CONFIGURE_DOMAIN" = "true" ]
then
  cfgCmd="/u01/oracle/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning /u01/oracle/dockertools/createOIMDomain.py -oh $ORACLE_HOME -jh $JAVA_HOME -parent $DOMAIN_ROOT -name $DOMAIN_NAME -password $ADMIN_PASSWORD -rcuDb $CONNECTION_STRING -rcuPrefix $RCUPREFIX -rcuSchemaPwd $DB_SCHEMA_PASSWORD -domainType $DOMAIN_TYPE -hostname $ADMIN_HOST"
  ${cfgCmd}
  retval=$?
  if [ $retval -ne 0 ];
  then
    echo "ERROR: Domain Configuration failed. Please check the logs"
    exit
  else
    export DOMAIN_HOME
    export JAVA_HOME
    chmod a+rx /u01/oracle/idm/server/bin/offlineConfigManager.sh
    cd /u01/oracle/idm/server/bin/
    offlineCmd="./offlineConfigManager.sh"
    ${offlineCmd}
    retval=$?
    if [ $retval -ne 0 ];
      then
        echo "ERROR: Offline config command failed. Please check the logs"
        exit
    fi
    # Write the Domain suc file...
    touch $CTR_DIR/OIM.DOMAINCFG.suc
    echo ${cfgCmd} >> $CTR_DIR/OIM.DOMAINCFG.suc

    cat > $CTR_DIR/contenv.sh <<EOF
CONNECTION_STRING=$CONNECTION_STRING
RCUPREFIX=$RCUPREFIX
ADMIN_PASSWORD=$ADMIN_PASSWORD
DB_PASSWORD=$DB_PASSWORD
DB_SCHEMA_PASSWORD=$DB_SCHEMA_PASSWORD
vol_name=$vol_name
EOF
  fi
fi

oimserver="oim_server1"
soaserver="soa_server1"

#
# Creating domain env file
#=========================
mkdir -p $DOMAIN_HOME/servers/AdminServer/security
mkdir -p $DOMAIN_HOME/servers/$soaserver/security
mkdir -p $DOMAIN_HOME/servers/$oimserver/security
#
# Password less Adminserver starting
#===================================
echo "username=weblogic" > $DOMAIN_HOME/servers/AdminServer/security/boot.properties
echo "password="$ADMIN_PASSWORD >> $DOMAIN_HOME/servers/AdminServer/security/boot.properties

#
# Password less Managed Server starting
#======================================
echo "username=weblogic" > $DOMAIN_HOME/servers/$soaserver/security/boot.properties
echo "password="$ADMIN_PASSWORD >> $DOMAIN_HOME/servers/$soaserver/security/boot.properties

#
# Password less Managed Server starting
#======================================
echo "username=weblogic" > $DOMAIN_HOME/servers/$oimserver/security/boot.properties
echo "password="$ADMIN_PASSWORD >> $DOMAIN_HOME/servers/$oimserver/security/boot.properties


#
# Setting env variables
#=======================
echo ". $DOMAIN_HOME/bin/setDomainEnv.sh" >> /u01/oracle/.bashrc
echo "export PATH=$PATH:/u01/oracle/common/bin:$DOMAIN_HOME/bin" >> /u01/oracle/.bashrc

updateListenAddress

if [ ! -f /u01/oracle/idm/server/ConnectorDefaultDirectory/ConnectorConfigTemplate.xml ] && [ -d /u01/oracle/idm/server/ConnectorDefaultDirectory_orig ]; then
    cp /u01/oracle/idm/server/ConnectorDefaultDirectory_orig/ConnectorConfigTemplate.xml /u01/oracle/idm/server/ConnectorDefaultDirectory
fi

if [ ! -f /u01/oracle/idm/server/ConnectorDefaultDirectory/ConnectorSchema.xsd ] && [ -d /u01/oracle/idm/server/ConnectorDefaultDirectory_orig ]; then
    cp /u01/oracle/idm/server/ConnectorDefaultDirectory_orig/ConnectorSchema.xsd /u01/oracle/idm/server/ConnectorDefaultDirectory
fi

if [ ! -f /u01/oracle/idm/server/ConnectorDefaultDirectory/readme.txt ] && [ -d /u01/oracle/idm/server/ConnectorDefaultDirectory_orig ]; then
    cp /u01/oracle/idm/server/ConnectorDefaultDirectory_orig/readme.txt /u01/oracle/idm/server/ConnectorDefaultDirectory
fi

if [ ! -d /u01/oracle/idm/server/ConnectorDefaultDirectory/targetsystems-lib ] && [ -d /u01/oracle/idm/server/ConnectorDefaultDirectory_orig ]; then
    cp -rf /u01/oracle/idm/server/ConnectorDefaultDirectory_orig/targetsystems-lib /u01/oracle/idm/server/ConnectorDefaultDirectory
fi


# Now we start the Admin server in this container...
/u01/oracle/dockertools/startAdmin.sh

sleep infinity
#tail -f $DOMAIN_HOME/servers/AdminServer/logs/AdminServer.log &
#childPID=$!
#wait $childPID
