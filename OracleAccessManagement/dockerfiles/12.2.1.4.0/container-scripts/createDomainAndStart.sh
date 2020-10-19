#!/bin/bash
#
#
#
#
# Copyright (c) 2019-2020 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Author: Kaushik C
#

export DOMAIN_HOME=$DOMAIN_ROOT/$DOMAIN_NAME

########### SIGINT handler ############
function _int() {
  echo "INFO: Stopping container."
  echo "INFO:   SIGINT received, shutting down Admin Server!"
  ${DOMAIN_HOME}/bin/stopWebLogic.sh
  exit;
}

########### SIGTERM handler ############
function _term() {
  echo "INFO: Stopping container."
  echo "INFO:   SIGTERM received, shutting down Admin Server!"
  ${DOMAIN_HOME}/bin/stopWebLogic.sh
  exit;
}

########### SIGKILL handler ############
function _kill() {
  echo "INFO: SIGKILL received, shutting down Admin Server!"
  ${DOMAIN_HOME}/bin/stopWebLogic.sh
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
  echo "INFO: ${s}" 
}

#==================================================
updateListenAddress() {
  mkdir -p ${DOMAIN_HOME}/logs

  export thehost=`hostname -I`
  echo "INFO: Updating the listen address - ${thehost} ${ADMIN_LISTEN_HOST}"
  cmd="${ORACLE_HOME}/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning ${SCRIPT_DIR}/updateListenAddress.py ${thehost} ${ADMIN_NAME} ${ADMIN_LISTEN_HOST}"
  echo ${cmd}
  echo "${cmd}" > ${DOMAIN_HOME}/logs/aslisten.log
  ${cmd} >> ${DOMAIN_HOME}/logs/aslisten.log 2>&1
}

# Set SIGINT handler
trap _int SIGINT

# Set SIGTERM handler
trap _term SIGTERM

#; Set SIGKILL handler
trap _kill SIGKILL

# Check that the User has passed on all the details needed to configure this image
# Settings to call RCU....
echo "CONNECTION_STRING=${CONNECTION_STRING:?"Please set CONNECTION_STRING for connecting to the Database"}"
echo "RCUPREFIX=${RCUPREFIX:?"Please set RCUPREFIX for the database schemas"}"

# Print Important Env Variables
echo "DOMAIN_HOME=$DOMAIN_HOME"


RUN_RCU="true"
CONFIGURE_DOMAIN="true"
export CONNECTION_STRING=$CONNECTION_STRING
export RCUPREFIX=$RCUPREFIX

export jdbc_url="jdbc:oracle:thin:@"$CONNECTION_STRING
export JDBC_URL="jdbc:oracle:thin:@"$CONNECTION_STRING

PMGR_MS_NAME=oam_policy_mgr1
mkdir -p ${CONTAINER_DIR}

# Create an Infrastructure domain
# set environments needed for the script to work
ADD_DOMAIN=1

if [ ! -f ${DOMAIN_HOME}/servers/${ADMIN_NAME}/logs/${ADMIN_NAME}.log ]; then
    ADD_DOMAIN=0
    echo "INFO: Admin Server not configured. Will run RCU and Domain Configuration Phase..."
else
   echo "INFO: Admin Server  configured. Will not run RCU and Domain Configuration Phase..."
   ADD_DOMAIN=1
fi
# Create Domain only if 1st execution
if [ $ADD_DOMAIN -eq 0 ];
then

  echo "Configuring Domain for first time "
  echo "Start the Admin and Managed Servers  "
  echo "====================================="
  
  echo "Loading RCU Phase"
  echo "================="
  
  echo "CONNECTION_STRING=$CONNECTION_STRING"
  echo "RCUPREFIX=$RCUPREFIX"
  echo "jdbc_url=$jdbc_url"

  echo "Creating Domain 1st execution"
  # Create Domain only if 1st execution

  #Only call RCU the first time we create the domain
  if [ -e $CONTAINER_DIR/RCU.$RCUPREFIX.suc ]
  then
      #RCU has already been executed successfully, no need to rerun
      RUN_RCU="false"
      echo "RCU has already been loaded.. skipping"
  fi

  if [ "$RUN_RCU" == "true" ]
  then
    #Set the password for RCU
    echo -e ${DB_PASSWORD}"\n"${DB_SCHEMA_PASSWORD} > ${ORACLE_HOME}/pwd.txt
    echo "Loading RCU into database with RCUPREFIX ${RCUPREFIX}"
    # Run the RCU to load the schemas into the database
    ${ORACLE_HOME}/oracle_common/bin/rcu -silent -createRepository -databaseType ORACLE -connectString ${CONNECTION_STRING} -dbUser ${DB_USER} -dbRole sysdba -useSamePasswordForAllSchemaUsers true -selectDependentsForComponents true -schemaPrefix ${RCUPREFIX} -component MDS -component MDS -component IAU -component IAU_APPEND -component IAU_VIEWER -component OPSS -component WLS -component STB -component OAM -f < ${ORACLE_HOME}/pwd.txt >> ${ORACLE_HOME}/RCU.out
    retval=$?

    if [ $retval -ne 0 ]; 
    then
      echo  "WARN: RCU has some error "
      #RCU was already called once and schemas are in the database
      #continue with Domain creation
      grep -q "RCU-6016 The specified prefix already exists" "${ORACLE_HOME}/RCU.out"
      if [ $? -eq 0 ] ; then
        echo  "WARN: RCU has already loaded schemas into the Database with RCUPREFIX ${RCUPREFIX}"
        echo  "WARN: RCU Ignore error"
      else
          echo "ERROR: RCU Loading Failed.. Please check the RCU logs"
          cat ${ORACLE_HOME}/RCU.out
          exit
      fi
    else
      # Write the rcu suc file... 
      touch $CONTAINER_DIR/RCU.$RCUPREFIX.suc
      	
      # Write the env file.. such that the passwords etc.. will be saved and we will 
      # be able to restart from the RCU
      cat > $CONTAINER_DIR/contenv.sh <<EOF
CONNECTION_STRING=$CONNECTION_STRING
RCUPREFIX=$RCUPREFIX
ADMIN_USER=$ADMIN_USER
ADMIN_PASSWORD=$ADMIN_PASSWORD
DB_PASSWORD=$DB_PASSWORD
DB_SCHEMA_PASSWORD=$DB_SCHEMA_PASSWORD
USER_PROJECTS_DIR=$USER_PROJECTS_DIR
EOF
    fi
    # cleanup : remove the password file for security
    rm -f "${ORACLE_HOME}/pwd.txt"
  fi

  #
  # Configuration of OAM domain
  #=============================
  if [ -e $CONTAINER_DIR/OAM.DOMAINCFG.suc ] 
  then
    CONFIGURE_DOMAIN="false"
    echo "INFO: Domain Already configured. Skipping Domain Configuration Phase..."
  fi
  
  if [ "$CONFIGURE_DOMAIN" = "true" ]
  then
  
    if [ -z "$SSLEnabled" ]; then
      SSLEnabled='true'
    else
      SSLEnabled=$SSLEnabled
    fi

    echo "Domain Configuration Phase"
    echo "=========================="
    echo "/u01/oracle/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning ${SCRIPT_DIR}/create_domain.py -oh $ORACLE_HOME -jh $JAVA_HOME -parent $DOMAIN_ROOT -name $DOMAIN_NAME -user $ADMIN_USER -password $ADMIN_PASSWORD -rcuDb $CONNECTION_STRING -rcuPrefix $RCUPREFIX -rcuSchemaPwd $DB_SCHEMA_PASSWORD -isSSLEnabled $SSLEnabled" 
    #export WL_HOME=${ORACLE_HOME}/wlserver
    cfgCmd="/u01/oracle/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning ${SCRIPT_DIR}/create_domain.py -oh $ORACLE_HOME -jh $JAVA_HOME -parent $DOMAIN_ROOT -name $DOMAIN_NAME -user $ADMIN_USER -password $ADMIN_PASSWORD -rcuDb $CONNECTION_STRING -rcuPrefix $RCUPREFIX -rcuSchemaPwd $DB_SCHEMA_PASSWORD -isSSLEnabled $SSLEnabled"
    #/u01/oracle/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning ${SCRIPT_DIR}/create_domain.py "-oh $ORACLE_HOME -jh $JAVA_HOME -parent $DOMAIN_ROOT -name $DOMAIN_NAME -password $ADMIN_PASSWORD -rcuDb $CONNECTION_STRING -rcuPrefix $RCUPREFIX -rcuSchemaPwd $DB_SCHEMA_PASSWORD -isSSLEnabled $SSLEnabled"
    echo "Cmd is ${cfgCmd}"
    ${cfgCmd}
    retval=$?
    if [ $retval -ne 0 ];
    then
        echo "Domain Creation Failed.. Please check the Domain Logs"
        exit
    fi
  
    #
    # Creating domain env file
    #=========================
    mkdir -p $DOMAIN_HOME/servers/${ADMIN_NAME}/security  
    mkdir -p $DOMAIN_HOME/servers/${OAM_MS_NAME}/security
    mkdir -p $DOMAIN_HOME/servers/${PMGR_MS_NAME}/security
    #
    # Password less AdminServer starting
    #===================================
    echo "username="$ADMIN_USER > $DOMAIN_HOME/servers/${ADMIN_NAME}/security/boot.properties
    echo "password="$ADMIN_PASSWORD >> $DOMAIN_HOME/servers/${ADMIN_NAME}/security/boot.properties
    
    #
    # Password less Managed Server starting
    #======================================
    echo "username="$ADMIN_USER > $DOMAIN_HOME/servers/${OAM_MS_NAME}/security/boot.properties
    echo "password="$ADMIN_PASSWORD >> $DOMAIN_HOME/servers/${OAM_MS_NAME}/security/boot.properties
    
    #
    # Password less Managed Server starting
    #======================================
    echo "username="$ADMIN_USER > $DOMAIN_HOME/servers/${PMGR_MS_NAME}/security/boot.properties
    echo "password="$ADMIN_PASSWORD >> $DOMAIN_HOME/servers/${PMGR_MS_NAME}/security/boot.properties
    
    #
    # Setting env variables
    #=======================
    echo ". $DOMAIN_HOME/bin/setDomainEnv.sh" >> ${HOME}/.bashrc
    echo "export PATH=$PATH:${ORACLE_HOME}/common/bin:$DOMAIN_HOME/bin" >> ${HOME}/.bashrc
  
    # Write the Domain suc file... 
    touch $CONTAINER_DIR/OAM.DOMAINCFG.suc
  
    cat > $CONTAINER_DIR/contenv.sh <<EOF
CONNECTION_STRING=$CONNECTION_STRING
RCUPREFIX=$RCUPREFIX
ADMIN_USER=$ADMIN_USER
ADMIN_PASSWORD=$ADMIN_PASSWORD
DB_PASSWORD=$DB_PASSWORD
DB_SCHEMA_PASSWORD=$DB_SCHEMA_PASSWORD
USER_PROJECTS_DIR=$USER_PROJECTS_DIR
EOF

  fi

fi

#Echo Env Details
# echo "Java Options: ${JAVA_OPTIONS}"
echo "Domain Root: ${DOMAIN_ROOT}"
echo "Domain Name: ${DOMAIN_NAME}"
echo "Domain Home: ${DOMAIN_HOME}"
echo "Oracle Home: ${ORACLE_HOME}"
echo "Logs Dir: ${DOMAIN_HOME}/logs"

cd ${ORACLE_HOME}

# Update Listen Address for the Admin Server
updateListenAddress
# Now we start the Admin server in this container... 
# ${DOMAIN_HOME}/bin/startWebLogic.sh &
${SCRIPT_DIR}/startAdmin.sh
retval=$?
if [ $retval -ne 0 ]; 
  then
    echo "ERROR: Failed to start Admin Server. Please check the logs"
    exit
fi

sleep infinity
