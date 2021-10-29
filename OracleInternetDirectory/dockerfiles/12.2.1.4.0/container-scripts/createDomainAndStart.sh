#!/bin/bash
#
# Copyright (c) 2021, Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Author: Pratyush Dash
#
export DOMAIN_HOME=$DOMAIN_ROOT/$DOMAIN_NAME
export WL_HOME=$ORACLE_HOME/wlserver
export oid_instance=${INSTANCE_NAME:-oid1}
export instance_type=${INSTANCE_TYPE:-PRIMARY}
export sleepBeforeConfig=${sleepBeforeConfig:-480}
########### SIGINT handler ############
function _int() {
  echo "INFO: Stopping container."
  echo "INFO:   SIGINT received, shutting down server!"
  cfgCmd="${ORACLE_HOME}/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning ${SCRIPT_DIR}/stop_oid_component.py -username $ADMIN_USER -adminpassword $ADMIN_PASSWORD -instance_Name $oid_instance"
echo "Cmd is ${cfgCmd}"
  ${cfgCmd}
  ${DOMAIN_HOME}/bin/stopWebLogic.sh
  ${DOMAIN_HOME}/bin/stopNodeManager.sh
  exit;
}

########### SIGTERM handler ############
function _term() {
  echo "INFO: Stopping container."
  echo "INFO:   SIGTERM received, shutting down server!"
    cfgCmd="${ORACLE_HOME}/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning ${SCRIPT_DIR}/stop_oid_component.py -username $ADMIN_USER -adminpassword $ADMIN_PASSWORD -instance_Name $oid_instance"
echo "Cmd is ${cfgCmd}"
  ${cfgCmd}
  ${DOMAIN_HOME}/bin/stopWebLogic.sh
  ${DOMAIN_HOME}/bin/stopNodeManager.sh
  exit;
}

########### SIGKILL handler ############
function _kill() {
  echo "INFO: SIGKILL received, shutting down the server!"
    cfgCmd="${ORACLE_HOME}/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning ${SCRIPT_DIR}/stop_oid_component.py -username $ADMIN_USER -adminpassword $ADMIN_PASSWORD -instance_Name $oid_instance"
echo "Cmd is ${cfgCmd}"
  ${cfgCmd}
  ${DOMAIN_HOME}/bin/stopWebLogic.sh
  ${DOMAIN_HOME}/bin/stopNodeManager.sh
  kill -9 $PID
  exit;
}


#==================================================
updateListenAddress() {
  mkdir -p ${DOMAIN_HOME}/logs

  export thehost=`hostname -f`
  echo "INFO: Updating the listen address - ${thehost} ${ADMIN_LISTEN_HOST}"
  cmd="${ORACLE_HOME}/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning ${SCRIPT_DIR}/updateListenAddress.py ${thehost} ${ADMIN_NAME} ${ADMIN_LISTEN_HOST}"
  echo ${cmd}
  echo "${cmd}" > ${DOMAIN_HOME}/logs/aslisten.log
  ${cmd} >> ${DOMAIN_HOME}/logs/aslisten.log 2>&1
}

function waitForServerPort() {

  connectString="${1}/${2}"

  echo "[$(date)] - Waiting for Server on ${connectString} to become available..."
  while :
  do
    (echo > /dev/tcp/${connectString}) >/dev/null 2>&1
    available=$?
    if [[ $available -eq 0 ]]; then
      echo "[$(date)] - Server (${connectString}) is now available. Proceeding..."
      break
    fi
    sleep 5
  done
}

function enable_ssl() {

  NOW=$(date '+%Y%m%d%H%M%S')
  hostName=`hostname -f`
  cur_dir="/u01/oracle/dockertools"
  WALLET_LOCATION="$DOMAIN_HOME/wallets/$hostName"
  export walletPassword=$SSL_WALLET_PASSWORD
  export LDAP_PORT=$LDAP_PORT
  export LDAPS_PORT=$LDAPS_PORT
  mkdir -p ${WALLET_LOCATION}
  if [ -f "${WALLET_LOCATION}/ewallet.p12" ]; then
    echo "Backing-up wallet to ${WALLET_LOCATION}/ewallet.p12.${NOW}"
    mv ${WALLET_LOCATION}/ewallet.p12 ${WALLET_LOCATION}/ewallet.p12.${NOW}
  fi
  if [ -f "${WALLET_LOCATION}/cwallet.sso" ]; then
    echo "Backing-up auto_login to ${WALLET_LOCATION}/cwallet.sso.${NOW}"
    mv ${WALLET_LOCATION}/cwallet.sso ${WALLET_LOCATION}/cwallet.sso.${NOW}
  fi
  . /u01/oracle/user_projects/domains/oid_domain/bin/setDomainEnv.sh
  export TNS_ADMIN=$DOMAIN_HOME/config/fmwconfig/components/OID/config
  export COMPONENT_NAME=$INSTANCE_NAME
  export PATH=$ORACLE_HOME/bin:$DOMAIN_HOME/bin:$ORACLE_HOME/ldap/bin:$PATH
  mkdir -p $cur_dir/$hostName
  cp -rf $cur_dir/ldap_modify.ldif $cur_dir/$hostName/ldap_modify.ldif
  sed -i -e "s:@host@:$hostName:g" $cur_dir/$hostName/ldap_modify.ldif
  sed -i -e "s:@component@:$COMPONENT_NAME:g" $cur_dir/$hostName/ldap_modify.ldif
  printf '%s\n' $walletPassword $walletPassword | orapki wallet create -wallet ${WALLET_LOCATION} -auto_login
  printf '%s\n' $walletPassword | orapki wallet add -wallet ${WALLET_LOCATION} -dn cn=$hostName -keysize 2048 -self_signed -validity 3650 -pwd $walletPassword -sign_alg sha256
  $ORACLE_HOME/bin/ldapmodify -f $cur_dir/$hostName/ldap_modify.ldif -h $hostName -p $LDAP_PORT -D cn=orcladmin -w $ORCL_ADMIN_PASSWORD
  oidctl connect=oiddb server=oidldapd stop
  oidctl connect=oiddb server=oidldapd flags="-p $LDAP_PORT -sport $LDAPS_PORT" host=$hostName start
  max_loop=20
  for ((count = 0; count < max_loop; count++)); do
  server_up=$(printf '%s\n' $walletPassword | $ORACLE_HOME/bin/ldapbind -D cn=orcladmin -w $ORCL_ADMIN_PASSWORD -h $hostName -p $LDAPS_PORT -U 2 -W "file:${WALLET_LOCATION}" -Q | grep -e 'bind successful' | wc -l || echo 0)
  if [ "$server_up" = "1" ]; then
    echo "SSL Setup completed successfully"
    break
  else
    sleep 10
    echo "Failed for $count time/times...."
  fi
  done
  
  if [ "$count" -eq "$max_loop" ]; then
    echo "Ldap ssl failed" >&2
    exit 1
  fi
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

NODEMGR_HOME=${DOMAIN_HOME}/nodemanager
export NODEMGR_HOME



RUN_RCU="true"
CONFIGURE_DOMAIN="true"
export CONNECTION_STRING=$CONNECTION_STRING
export RCUPREFIX=$RCUPREFIX

export jdbc_url="jdbc:oracle:thin:@"$CONNECTION_STRING
export JDBC_URL="jdbc:oracle:thin:@"$CONNECTION_STRING

mkdir -p ${CONTAINER_DIR}

# Create an Infrastructure domain
# set environments needed for the script to work
#ADD_DOMAIN=1

# Create Domain only if 1st execution
if [ ! -f  $DOMAIN_HOME/.oidconfigured ] && [ $instance_type == "PRIMARY" ] ;
then

  echo "Configuring Domain for first time "
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
    ${ORACLE_HOME}/oracle_common/bin/rcu -silent -createRepository -databaseType ORACLE -connectString ${CONNECTION_STRING} -dbUser ${DB_USER} -dbRole sysdba -useSamePasswordForAllSchemaUsers true -selectDependentsForComponents true -schemaPrefix ${RCUPREFIX} -component MDS -component OPSS -component STB -component OID -component IAU -component WLS -f < ${ORACLE_HOME}/pwd.txt >> ${ORACLE_HOME}/RCU.out
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
          exit 1
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
ORCL_ADMIN_PASSWORD=$ORCL_ADMIN_PASSWORD
REALM_DN=$REALM_DN

EOF
    fi
    # cleanup : remove the password file for security
    rm -f "${ORACLE_HOME}/pwd.txt"
  fi

  #
  # Configuration of OID domain
  #=============================
  
    echo "Domain Configuration Phase"
    echo "=========================="
    echo "${ORACLE_HOME}/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning {SCRIPT_DIR}/createOIDDomain.py -oh $ORACLE_HOME -jh $JAVA_HOME -parent $DOMAIN_ROOT -name $DOMAIN_NAME -user $ADMIN_USER -password $ADMIN_PASSWORD -rcuDb $CONNECTION_STRING -rcuPrefix $RCUPREFIX -rcuSchemaPwd $DB_SCHEMA_PASSWORD" 
    cfgCmd="${ORACLE_HOME}/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning ${SCRIPT_DIR}/createOIDDomain.py -oh $ORACLE_HOME -jh $JAVA_HOME -parent $DOMAIN_ROOT -name $DOMAIN_NAME -user $ADMIN_USER -password $ADMIN_PASSWORD -rcuDb $CONNECTION_STRING -rcuPrefix $RCUPREFIX -rcuSchemaPwd $DB_SCHEMA_PASSWORD"
    echo "Cmd is ${cfgCmd}"
    ${cfgCmd}
    retval=$?
    if [ $retval -ne 0 ];
    then
        echo "Domain Creation Failed.. Please check the Domain Logs"
        exit 1
    fi
  
    #
    # Creating domain env file
    #=========================
    mkdir -p $DOMAIN_HOME/servers/${ADMIN_NAME}/security



    #
    # Password less AdminServer starting
    #===================================
    echo "username="$ADMIN_USER > $DOMAIN_HOME/servers/${ADMIN_NAME}/security/boot.properties
    echo "password="$ADMIN_PASSWORD >> $DOMAIN_HOME/servers/${ADMIN_NAME}/security/boot.properties

    # Password less NodeManager starting

    echo "username=$ADMIN_USER" >> $DOMAIN_HOME/config/nodemanager/nm_password.properties
    echo "password=$ADMIN_PASSWORD" >> $DOMAIN_HOME/config/nodemanager/nm_password.properties

    
    #
    # Setting env variables
    #=======================
    echo ". $DOMAIN_HOME/bin/setDomainEnv.sh" >> ${HOME}/.bashrc
    echo "export PATH=$PATH:${ORACLE_HOME}/common/bin:$DOMAIN_HOME/bin" >> ${HOME}/.bashrc
  

  
    cat > $CONTAINER_DIR/contenv.sh <<EOF
CONNECTION_STRING=$CONNECTION_STRING
RCUPREFIX=$RCUPREFIX
ADMIN_USER=$ADMIN_USER
ADMIN_PASSWORD=$ADMIN_PASSWORD
DB_PASSWORD=$DB_PASSWORD
DB_SCHEMA_PASSWORD=$DB_SCHEMA_PASSWORD
USER_PROJECTS_DIR=$USER_PROJECTS_DIR
ORCL_ADMIN_PASSWORD=$ORCL_ADMIN_PASSWORD
REALM_DN=$REALM_DN
EOF


#Echo Env Details
    echo "Java Options: ${JAVA_OPTIONS}"
    echo "Domain Root: ${DOMAIN_ROOT}"
    echo "Domain Name: ${DOMAIN_NAME}"
    echo "Domain Home: ${DOMAIN_HOME}"
    echo "Oracle Home: ${ORACLE_HOME}"
    echo "Logs Dir: ${DOMAIN_HOME}/logs"



# Update Listen Address for the Admin Server
#updateListenAddress
# Now we start the NodeManager in this container...

    LOGFILE=${DOMAIN_HOME}/logs/nodemanager.log

    mkdir -p ${DOMAIN_HOME}/logs
    rm -f ${LOGFILE}

# Start node manager
    ${DOMAIN_HOME}/bin/startNodeManager.sh > ${LOGFILE} 2>&1 &
    statusfile=/tmp/notifyfifo.$$
    rm -f $statusfile
#Check if Node Manager is up and running by inspecting logs
    mkfifo "${statusfile}" || exit 1
{
    # run tail in the background so that the shell can kill tail when notified that grep has exited
    tail -f ${LOGFILE} &
    # remember tail's PID
    tailpid=$!
    # wait for notification that grep has exited
    read templine <${statusfile}
                        echo ${templine}
    # grep has exited, time to go
    kill "${tailpid}"
} | {
    grep -m 1 "Secure socket listener started on port 5556"
    # notify the first pipeline stage that grep is done
        echo "RUNNING" > ${DOMAIN_HOME}/logs/Nodemanage.status
        echo "Node manager is running"
    echo > ${statusfile}
}
# clean up temporary files
    rm ${statusfile}

    if [ -f ${DOMAIN_HOME}/logs/Nodemanage.status ]; then
    echo "Node manager running, hence starting Admin server"

# Update Listen Address for the Admin Server
    updateListenAddress
# Now we start the Admin server in this container... 
    ${SCRIPT_DIR}/startAdmin.sh
    retval=$?
    if [ $retval -ne 0 ]; 
        then
        echo "ERROR: Failed to start Admin Server. Please check the logs"
        exit 1
    fi
fi

    export oid_instance=${INSTANCE_NAME:-oid1}
    export adminhostname=${ADMIN_LISTEN_HOST:-}
    export adminport=${ADMIN_LISTEN_PORT:-}
    export host=${INSTANCE_HOST:-oidhost1}
    export admin_Password=${ORCL_ADMIN_PASSWORD:-}
    export realm_dn=${REALM_DN:-dc=us,dc=oracle,dc=com}
    export LDAP_PORT=${LDAP_PORT:-3060}
    export LDAPS_PORT=${LDAPS_PORT:-3131}
# Start OID Server1

    echo "ADMIN_LISTEN_HOST is ${adminhostname}"
    echo "ADMIN_LISTEN_PORT is ${adminport}"
    echo "Realm dn is ${realm_dn} "



    echo "Creating OID instance Phase"
    echo "=========================="
    export JAVA_HOME=$ORACLE_HOME/oracle_common/jdk/jre/
    export PATH=$JAVA_HOME/bin:$PATH

    cfgCmd="${ORACLE_HOME}/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning ${SCRIPT_DIR}/create_oid1.py -username $ADMIN_USER -adminpassword $ADMIN_PASSWORD -rcuSchemaPwd $DB_SCHEMA_PASSWORD -adminPassword $admin_Password -instance_Name $oid_instance -admin_Port $adminport -admin_Hostname $adminhostname"
    echo "Cmd is ${cfgCmd}"
    ${cfgCmd}
    retval=$?
    if [ $retval -ne 0 ];
    then
        echo "Starting OID Failed.. Please check the server Logs"
        exit 1
    else
       touch $DOMAIN_HOME/.oidconfigured
    fi
    sleep 30
    echo "Enable SSL LDAP....."
    enable_ssl
# Start OID Server1


# If configured just start the oid instance
elif [ $instance_type == "SECONDARY" ] && [ ! -f $DOMAIN_HOME/${oid_instance}.configured ];
then
    export oid_instance=${INSTANCE_NAME:-oid1}
    export adminhostname=${ADMIN_LISTEN_HOST:-}
    export adminport=${ADMIN_LISTEN_PORT:-}
    export host=${INSTANCE_HOST:-oidhost1}
    export admin_Password=${ORCL_ADMIN_PASSWORD:-}
    export COMPONENT_NAME=${oid_instance:-oid1}
    export LDAP_PORT=${LDAP_PORT:-3060}
    export LDAPS_PORT=${LDAP_PORTS:-3131}
    echo "====================================="
    echo "Check to see if oidhost1 is up and running......"
    #sleep $sleepBeforeConfig
    waitForServerPort ${ADMIN_LISTEN_HOST} ${ADMIN_LISTEN_PORT}
    waitForServerPort ${ADMIN_LISTEN_HOST} ${LDAP_PORT}
    . /u01/oracle/user_projects/domains/oid_domain/bin/setDomainEnv.sh
    export PATH=$ORACLE_HOME/bin:$DOMAIN_HOME/bin:$ORACLE_HOME/ldap/bin:$PATH
    export TNS_ADMIN=$DOMAIN_HOME/config/fmwconfig/components/OID/config
    export COMPONENT_NAME=${INSTANCE_NAME}
    cfgCmd="oidmon connect=oiddb start"
    echo "Cmd is ${cfgCmd}"
    ${cfgCmd}
    retval=$?
    if [ $retval -ne 0 ];
    then
      echo "OID mon start failed.. Please check the server Logs"
      exit 1
    else 
      echo "OID mon started successfully"
    fi
    sleep 30
    echo "Adding instance ${COMPONENT_NAME}"
    oidctl connect=oiddb server=oidldapd flags="port=$LDAP_PORT sport=$LDAPS_PORT" add
    retval=$?
    if [ $retval -ne 0 ];
    then
      echo "OIDCTL failed to add instance.Please check the server Logs"
      exit 1
    else
      sleep 120
      touch $DOMAIN_HOME/${oid_instance}.configured
    fi
    sleep 30
    echo "Setting SSL for LDAP for ${oid_instance}...."
    enable_ssl
else
    if [ $instance_type == "PRIMARY" ];then
      echo "Domain and instance has been configured already. Restarting instance ${oid_instance}...."
      ${DOMAIN_HOME}/bin/startNodeManager.sh &
      sleep 300
      echo "Starting Admin Server...."
      ${DOMAIN_HOME}/bin/startWebLogic.sh &
      retval=$?
      if [ $retval -ne 0 ];
      then
        echo "ERROR: Failed to start Admin Server. Please check the logs"
        exit 1
      fi
      sleep 180
      echo "OID domain configured and oid server needs to be started"
      . ${ORACLE_HOME}/wlserver/server/bin/setWLSEnv.sh
      cfgCmd="${ORACLE_HOME}/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning ${SCRIPT_DIR}/start_oid_component.py -username $ADMIN_USER -adminpassword $ADMIN_PASSWORD -instance_Name $oid_instance"
      echo "Cmd is ${cfgCmd}"
      ${cfgCmd}
      retval=$?
      if [ $retval -ne 0 ];
      then
        echo "Starting OID Failed.. Please check the server Logs"
        exit 1
      fi
    else
       echo "Domain and instance already configured. Restarting instance ${INSTANCE_NAME} ...."
       . /u01/oracle/user_projects/domains/oid_domain/bin/setDomainEnv.sh
       export PATH=$ORACLE_HOME/bin:$DOMAIN_HOME/bin:$ORACLE_HOME/ldap/bin:$PATH
       export TNS_ADMIN=$DOMAIN_HOME/config/fmwconfig/components/OID/config
       export COMPONENT_NAME=${INSTANCE_NAME}
       cfgCmd="oidmon connect=oiddb start"
       echo "Cmd is ${cfgCmd}"
       ${cfgCmd}
       retval=$?
       if [ $retval -ne 0 ];
       then
         echo "OID mon start Failed.. Please check the server Logs"
         exit 1
       else
         echo "OID mon started successfully"
       fi
       sleep 30
       echo "Starting instance ${COMPONENT_NAME}"
       oidctl connect=oiddb server=oidldapd flags="port=$LDAP_PORT sport=$LDAPS_PORT" start
       retval=$?
       if [ $retval -ne 0 ];
       then
         echo "Starting OID failed.. Please check the server Logs"
         exit 1
       fi
     fi
fi
sleep infinity

