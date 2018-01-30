#!/bin/bash
#
# Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.

########### SIGINT handler ############
function _int() {
  echo "INFO: Stopping container."
  echo "INFO:   SIGINT received, shutting down Admin Server!"
  /u01/oracle/user_projects/domains/${DOMAIN_NAME}/bin/stopWebLogic.sh
  exit;
}

########### SIGTERM handler ############
function _term() {
   echo "SIGTERM received, Stoping Agent"
     /u01/oracle/user_projects/domains/${DOMAIN_NAME}/bin/stopWebLogic.sh
   exit;
}

########### SIGKILL handler ############
function _kill() {
  echo "INFO: SIGKILL received, shutting down Admin Server!"
  /u01/oracle/user_projects/domains/${DOMAIN_NAME}/bin/stopWebLogic.sh
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

# Set SIGINT handler
trap _int SIGINT

# Set SIGTERM handler
trap _term SIGTERM

# Set SIGKILL handler
trap _kill SIGKILL

echo "DB_HOST=${DB_HOST:?"Please set DB_HOST"}"
echo "DB_PORT=${DB_PORT:?"Please set DB_PORT"}"
echo "DB_SERVICE=${DB_SERVICE:?"Please set DB_SERVICE"}"

echo "RCUPREFIX=${RCUPREFIX:?"Please set RCUPREFIX"}"
echo "DB_PASSWORD=${DB_PASSWORD:?"Please set DB_PASSWORD"}"

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

if [ -z ${DOMAIN_PASSWORD} ]
then
    # Auto generate Weblogic Administrator password
    temp_pwd=$(rand_pwd)
    #Password should not start with a number for database
    f_str=`echo $temp_pwd|cut -c1|tr [0-9] [A-Z]`
    s_str=`echo $temp_pwd|cut -c2-`
    DOMAIN_PASSWORD=${f_str}${s_str}
    echo ""
    echo "    Weblogic Administrator password Auto Generated :"
    echo ""
    echo "    ----> Weblogic Administrator password: $DOMAIN_PASSWORD"
    echo ""
fi


export DB_HOST=$DB_HOST
export DB_PORT=$DB_PORT
export DB_SERVICE=$DB_SERVICE
export CONNECTION_STRING="${DB_HOST}:${DB_PORT}/${DB_SERVICE}"
export RCUPREFIX=$RCUPREFIX
export DB_SCHEMA_PASSWORD=$DB_SCHEMA_PASSWORD
export DB_PASSWORD=$DB_PASSWORD
export jdbc_url="jdbc:oracle:thin:@"$CONNECTION_STRING

export USE_TWO_PHASE_RCU=false

CONTAINERCONFIG_DIR=$ORACLE_HOME/user_projects/ContainerData

#
# Creating schemas needed for sample domain ####
#===============================================
#

RUN_RCU="true"
CONFIGURE_DOMAIN="true"

if [ -d  $CONTAINERCONFIG_DIR ] 
then
	# First load the Env Data from the env file... 
	if [ -e $CONTAINERCONFIG_DIR/contenv.sh ] 
	then
		. $CONTAINERCONFIG_DIR/contenv.sh
		#reset the JDBC URL
		export jdbc_url="jdbc:oracle:thin:@"$CONNECTION_STRING
	fi
else
	mkdir -p $CONTAINERCONFIG_DIR
fi

if [ -e $CONTAINERCONFIG_DIR/RCU.$RCUPREFIX.suc ] 
then
	#RCU has already been executed successfully, no need to rerun
	RUN_RCU="false"
	echo "EDQ RCU has already been loaded.. skipping"
fi
if [ "$RUN_RCU" == "true" ] 
then
    EDQ_COMPS="-component STB -component EDQ_CONF -component EDQ_RES -component EDQ_STAGING"
    OTHER_COMPS="-component IAU -component IAU_APPEND -component IAU_VIEWER -component OPSS -component MDS -component WLS" 
    # Run the RCU.. it hasnt been loaded before.. 	
echo -e "$DB_PASSWORD\n$DB_SCHEMA_PASSWORD" | $ORACLE_HOME/oracle_common/bin/rcu -silent -createRepository -connectString $CONNECTION_STRING -dbUser sys -dbRole sysdba -useSamePasswordForAllSchemaUsers true -schemaPrefix $RCUPREFIX $EDQ_COMPS $OTHER_COMPS
    retval=$?

    if [ $retval -ne 0 ]; 
    then
    	echo "RCU Loading Failed.. Check the RCU logs"
    	exit
    else
    	# Write the rcu suc file... 
    	touch $CONTAINERCONFIG_DIR/RCU.$RCUPREFIX.suc
    fi
fi



#
# Configuration of EDQ domain
#=============================
if [ -e $CONTAINERCONFIG_DIR/EDQ.Domain.Configure.suc ] 
then
	CONFIGURE_DOMAIN="false"
	echo "Domain Already configured.. skipping"
fi

if [ "$CONFIGURE_DOMAIN" == "true" ] 
then
	echo "Running .. "
        echo "$ORACLE_HOME/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning $ORACLE_HOME/container-scripts/CreateEDQDomain.py -oh $ORACLE_HOME -jh $JAVA_HOME -parent $DOMAIN_ROOT -name $DOMAIN_NAME -dbhost $DB_HOST -dbport $DB_PORT -dbservice $DB_SERVICE -rcuPrefix $RCUPREFIX -rcuSchemaPwd $DB_SCHEMA_PASSWORD -password $DOMAIN_PASSWORD -adminPort $ADMIN_PORT -edqPort $EDQ_PORT"
	$ORACLE_HOME/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning $ORACLE_HOME/container-scripts/CreateEDQDomain.py -oh $ORACLE_HOME -jh $JAVA_HOME -parent $DOMAIN_ROOT -name $DOMAIN_NAME -dbhost $DB_HOST -dbport $DB_PORT -dbservice $DB_SERVICE -rcuPrefix $RCUPREFIX -rcuSchemaPwd $DB_SCHEMA_PASSWORD -password $DOMAIN_PASSWORD -adminPort $ADMIN_PORT -edqPort $EDQ_PORT
	retval=$?
	if [ $retval -ne 0 ]
	then
	   	echo "Domain Configuration failed.. please check the logs for errors"
	   	exit
	else
	   	# Write the Domain suc file... 
	   	touch $CONTAINERCONFIG_DIR/EDQ.Domain.Configure.suc
                echo "$ORACLE_HOME/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning $ORACLE_HOME/container-scripts/CreateEDQDomain.py -oh $ORACLE_HOME -jh $JAVA_HOME -parent $DOMAIN_ROOT -name $DOMAIN_NAME -dbhost $DB_HOST -dbport $DB_PORT -dbservice $DB_SERVICE -rcuPrefix $RCUPREFIX -rcuSchemaPwd $DB_SCHEMA_PASSWORD -password $DOMAIN_PASSWORD" >> $CONTAINERCONFIG_DIR/EDQ.Domain.Configure.suc
	   	echo "CONNECTION_STRING=$CONNECTION_STRING" > $CONTAINERCONFIG_DIR/contenv.sh
	   	echo "RCUPREFIX=$RCUPREFIX" >> $CONTAINERCONFIG_DIR/contenv.sh
	   	echo "DB_SCHEMA_PASSWORD=$DB_SCHEMA_PASSWORD" >> $CONTAINERCONFIG_DIR/contenv.sh

                # Setting env variables
                #=======================
                echo ". $DOMAIN_ROOT/$DOMAIN_NAME/bin/setDomainEnv.sh" >> $ORACLE_HOME/.bashrc
                echo "export PATH=$PATH:$ORACLE_HOME/common/bin:$DOMAIN_ROOT/$DOMAIN_NAME/bin" >> $ORACLE_HOME/.bashrc
	fi
fi
# Starting Admin Server 
#======================

echo "Starting Admin Server"

$DOMAIN_ROOT/$DOMAIN_NAME/bin/startWebLogic.sh > $ORACLE_HOME/logs/startAdmini$$.log 2>&1 &

tail -f $ORACLE_HOME/logs/startAdmini$$.log 

childPID=$!
wait $childPID
