#!/bin/bash
#
#
# Copyright (c) 2021 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
# Author:Arnab Nandi <arnab.x.nandi@oracle.com>
#

export AGENT_DOMAIN_HOME="/u01/oracle/veridata/agent"
export AGENT_DEPLOY_LOCATION_PATH="/u01/oracle/${AGENT_DEPLOY_DIRECTORY}"
echo "AGENT_DEPLOY_LOCATION_PATH is: " $AGENT_DEPLOY_LOCATION_PATH

#=================================================================
function _int() {
   echo "Stopping Veridata Agent."
   echo "SIGTERM received, shutting down the agent!"
   ${AGENT_DEPLOY_LOCATION_PATH}/agent.sh stop
   exit;
}
########### SIGTERM handler ############
function _term() {
   echo "Stopping Veridata Agent."
   echo "SIGTERM received, shutting down the agent!"
   ${AGENT_DEPLOY_LOCATION_PATH}/agent.sh stop
   exit;
}

########### SIGKILL handler ############
function _kill() {
   echo "Stopping Veridata Agent."
   echo "SIGTERM received, shutting down the agent!"
   ${AGENT_DEPLOY_LOCATION_PATH}/agent.sh stop
   exit;
}

trap _int SIGINT
trap _term SIGTERM
trap _kill SIGKILL

createVeridataAgent="True"

if [ -f $AGENT_DEPLOY_LOCATION_PATH/agent.properties ]
then
    ls -ltr $AGENT_DEPLOY_LOCATION_PATH
	  echo "Veridata Agent is installed."
	  createVeridataAgent="False"
fi

if [ -z ${APPLY_PATCH} ]
then
    export APPLY_PATCH="True"
fi


if [ "${createVeridataAgent}" == "True" ]
then

    echo "Creating Veriata Agent ${AGENT_DOMAIN_HOME}"

    ${AGENT_DOMAIN_HOME}/agent_config.sh ${AGENT_DEPLOY_LOCATION_PATH}
    samplePropFile="${AGENT_DEPLOY_LOCATION_PATH}/agent.properties.sample"
    propFile="${AGENT_DEPLOY_LOCATION_PATH}/agent.properties"
    sampleDirectory="${AGENT_DEPLOY_LOCATION_PATH}/sample_properties"

    if [  -d $sampleDirectory ]
    then
       samplePropFile="${AGENT_DEPLOY_LOCATION_PATH}/sample_properties/agent.properties.${AGENT_DATABASE_TYPE}"
    fi

    echo $samplePropFile
    cp ${samplePropFile} ${propFile}
    propFileBak="${AGENT_DEPLOY_LOCATION_PATH}/agent.properties.bak"

    search="<server.port>"
    replace="${AGENT_PORT}"
    sed "s/${search}/${replace}/g" ${propFile} > ${propFileBak}
    cp ${propFileBak} ${propFile}

    search="<database.url>"
    replace="${AGENT_JDBC_URL}"
    sed "s/${search}/${replace}/g" ${propFile} > ${propFileBak}
    cp ${propFileBak} ${propFile}

    search="#server.jdbcDriver"
    replace="server.jdbcDriver"
    sed "s/${search}/${replace}/g" ${propFile} > ${propFileBak}
    cp ${propFileBak} ${propFile}

    search="ojdbc7.jar"
    replace="ojdbc8.jar"
    sed "s/${search}/${replace}/g" ${propFile} > ${propFileBak}
    cp ${propFileBak} ${propFile}

    search="<server.jdbcDriver>"
    replace="ojdbc8.jar"
    sed "s/${search}/${replace}/g" ${propFile} > ${propFileBak}
    cp ${propFileBak} ${propFile}
fi



#starting the veridata agent

${AGENT_DEPLOY_LOCATION_PATH}/agent.sh start
sleep 30
tail -f ${AGENT_DEPLOY_LOCATION_PATH}/logs/veridata-agent.log
childPID=$!
wait $childPID
