#!/bin/bash
#
# Copyright (c) 2017, Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#


########### SIGINT handler ############
function _int() {
   echo "SIGINT received, Stoping Agent"
   $DOMAIN_ROOT/$DOMAIN_NAME/bin/agentstop.sh -NAME=OracleDIAgent1
   exit;
}

########### SIGTERM handler ############
function _term() {
   echo "SIGTERM received, Stoping Agent"
   $DOMAIN_ROOT/$DOMAIN_NAME/bin/agentstop.sh -NAME=OracleDIAgent1
   exit;
}

########### SIGKILL handler ############
function _kill() {
   echo "SIGKILL received"
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

# Set SIGINT handler
trap _int SIGINT

# Set SIGTERM handler
trap _term SIGTERM

# Set SIGKILL handler
trap _kill SIGKILL

echo "CONNECTION_STRING=${CONNECTION_STRING:?"Please set CONNECTION_STRING"}"
echo "RCUPREFIX=${RCUPREFIX:?"Please set RCUPREFIX"}"
echo "DB_PASSWORD=${DB_PASSWORD:?"Please set DB_PASSWORD"}"
echo "HOST_NAME=${HOST_NAME:?"Please set HOST_NAME"}"

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

if [ -z ${SUPERVISOR_PASSWORD} ]
then
    # Auto generate ODI SUPERVISOR password
    temp_pwd=$(rand_pwd)
    #Password should not start with a number for database
    f_str=`echo $temp_pwd|cut -c1|tr [0-9] [A-Z]`
    s_str=`echo $temp_pwd|cut -c2-`
    SUPERVISOR_PASSWORD=${f_str}${s_str}
    echo ""
    echo "    ODI SUPERVISOR password Auto Generated :"
    echo ""
    echo "    ----> SUPERVISOR password: ${SUPERVISOR_PASSWORD}"
    echo ""
fi

if [ -z ${WORK_REPO_NAME} ]
then
    # Default Work Repo name kepping WORKREP
    WORK_REPO_NAME=WORKREP
    echo ""
    echo "    Using default name for ODI WORK REPO : WORKREP"
    echo ""
fi


if [ -z ${WORK_REPO_PASSWORD} ]
then
    # Auto generate ODI WORKREP password
    temp_pwd=$(rand_pwd)
    #Password should not start with a number for database
    f_str=`echo $temp_pwd|cut -c1|tr [0-9] [A-Z]`
    s_str=`echo $temp_pwd|cut -c2-`
    WORK_REPO_PASSWORD=${f_str}${s_str}
    echo ""
    echo "    ODI WORK REPO password Auto Generated :"
    echo ""
    echo "    ----> WORK REPO password: ${WORK_REPO_PASSWORD}"
    echo ""
fi

export CONNECTION_STRING=$CONNECTION_STRING
export RCUPREFIX=$RCUPREFIX
export DB_SCHEMA_PASSWORD=$DB_SCHEMA_PASSWORD
export DB_PASSWORD=$DB_PASSWORD
export SUPERVISOR_PASSWORD=$SUPERVISOR_PASSWORD
export WORK_REPO_NAME=$WORK_REPO_NAME
export WORK_REPO_PASSWORD=$WORK_REPO_PASSWORD
export jdbc_url="jdbc:oracle:thin:@"$CONNECTION_STRING

export USE_TWO_PHASE_RCU=false
PWD=$ORACLE_HOME/pwd.txt
echo $DB_PASSWORD > $PWD
echo $DB_SCHEMA_PASSWORD >> $PWD
#echo $SUPERVISOR_PASSWORD >> $PWD
echo D >> $PWD
#echo $WORK_REPO_NAME >> $PWD
#echo $WORK_REPO_PASSWORD >> $PWD
echo AES-128 >> $PWD


CONTAINERCONFIG_DIR=$ORACLE_HOME/user_projects/ContainerData

#
# Creating schemas needed for sample domain ####
#===============================================
#

RUN_RCU="true"
CONFIGURE_DOMAIN="true"
CONFIGURE_AGENT="true"

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
	echo "ODI RCU has already been loaded.. skipping"
fi

if [ "$RUN_RCU" == "true" ] 
then
    # Run the RCU.. it hasnt been loaded before.. 	
    $ORACLE_HOME/oracle_common/bin/rcu -silent -createRepository -connectString $CONNECTION_STRING -dbUser sys -dbRole sysdba -useSamePasswordForAllSchemaUsers true -schemaPrefix $RCUPREFIX -component ODI < $PWD
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

rm -rf $PWD

#
# Configuring ODI Agent
#=======================

if [ -e $CONTAINERCONFIG_DIR/ODI.Agent.Configure.suc ]
then
        CONFIGURE_AGENT="false"
        echo "Agent Already configured.. skipping"
fi

if [ "$CONFIGURE_AGENT" == "true" ]
then
        CP=$ORACLE_HOME/odi/common/fmwprov/odi_config.jar:$ORACLE_HOME/odi/plugins/cam/oracle.odi-cam.jar
        my_host="$HOST_NAME"
        agent_name="OracleDIAgent1"
        agent_port=$ODI_AGENT_PORT
        agent_app="oraclediagent"
        agent_protocol="http"

        $JAVA_HOME/bin/java -cp $CP oracle.odi.util.odiConfigAgent ${RCUPREFIX}_ODI_REPO $DB_SCHEMA_PASSWORD $jdbc_url $agent_name $my_host $agent_port $agent_app $agent_protocol $agent_name SUPERVISOR $SUPERVISOR_PASSWORD
        retval=$?
        if [ $retval -ne 0 ]
        then
                echo "Agent creation failed.. please check the logs for errors"
                exit
        else
                echo "Agent $agent_name created Successfully"
                touch $CONTAINERCONFIG_DIR/ODI.Agent.Configure.suc
        fi
fi

#
# Configuration of ODI domain
#=============================
if [ -e $CONTAINERCONFIG_DIR/ODI.Domain.Configure.suc ] 
then
	CONFIGURE_DOMAIN="false"
	echo "Domain Already configured.. skipping"
fi

if [ "$CONFIGURE_DOMAIN" == "true" ] 
then
	$ORACLE_HOME/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning $ORACLE_HOME/container-scripts/CreateODIDomain.py -oh $ORACLE_HOME -jh $JAVA_HOME -parent $DOMAIN_ROOT -name $DOMAIN_NAME -rcuDb $CONNECTION_STRING -rcuPrefix $RCUPREFIX -rcuSchemaPwd $DB_SCHEMA_PASSWORD -supervisorPwd $SUPERVISOR_PASSWORD
	retval=$?
	if [ $retval -ne 0 ]
	then
	   	echo "Domain Configuration failed.. please check the logs for errors"
	   	exit
	else
	   	# Write the Domain suc file... 
	   	touch $CONTAINERCONFIG_DIR/ODI.Domain.Configure.suc
	   	echo "$ORACLE_HOME/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning $ORACLE_HOME/container-scripts/CreateODIDomain.py -oh $ORACLE_HOME -jh $JAVA_HOME -parent $DOMAIN_ROOT -name $DOMAIN_NAME -rcuDb $CONNECTION_STRING -rcuPrefix $RCUPREFIX -rcuSchemaPwd $DB_SCHEMA_PASSWORD" >> $CONTAINERCONFIG_DIR/ODI.Domain.Configure.suc
	   	echo "CONNECTION_STRING=$CONNECTION_STRING" > $CONTAINERCONFIG_DIR/contenv.sh
	   	echo "RCUPREFIX=$RCUPREFIX" >> $CONTAINERCONFIG_DIR/contenv.sh
	   	echo "DB_SCHEMA_PASSWORD=$DB_SCHEMA_PASSWORD" >> $CONTAINERCONFIG_DIR/contenv.sh

                # Setting env variables
                #=======================
                echo ". $DOMAIN_ROOT/$DOMAIN_NAME/bin/setODIDomainEnv.sh" >> $ORACLE_HOME/.bashrc
                echo "export PATH=$PATH:$ORACLE_HOME/common/bin:$DOMAIN_ROOT/$DOMAIN_NAME/bin" >> $ORACLE_HOME/.bashrc
	fi
fi


# Starting ODI Agent
#======================

echo "Starting ODI Agent"

$DOMAIN_ROOT/$DOMAIN_NAME/bin/agent.sh -NAME=OracleDIAgent1 > $ORACLE_HOME/logs/startAgent$$.log 2>&1 &

tail -f $ORACLE_HOME/logs/startAgent$$.log &

childPID=$!
wait $childPID

