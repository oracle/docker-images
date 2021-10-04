#! /bin/bash
#
#Copyright (c) 2021 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Pass in the managed server name to run and the mapped port
# Author:Arnab Nandi <arnab.x.nandi@oracle.com>

version=$1

set_context() {
   scriptDir="$( cd "$( dirname "$0" )" && pwd )"
   if [ ! -d "${scriptDir}" ]; then
       echo "Unable to determine the working directory for the OracleFMWInfrastructure image"
       echo "Using shell /bin/sh to determine and found ${scriptDir}"
       clean_and_exit
   fi
   echo "Context for docker build is ${scriptDir}"
}

extract_env() {
   env_value=`awk '{print}' $2 | grep ^$1= | cut -d "=" -f2`
   if [ -n "$env_value" ]; then
      env_arg=`echo $1=$env_value`
      echo " env_arg: $env_arg"
      export $env_arg
   fi
}

set_context


extract_env AGENT_HOST_VOLUME ${scriptDir}/vdtagent.env
extract_env AGENT_CONTAINER_NAME ${scriptDir}/vdtagent.env
extract_env AGENT_PORT ${scriptDir}/vdtagent.env
extract_env AGENT_DEPLOY_DIRECTORY ${scriptDir}/vdtagent.env


agent_host() {
   agentvolume=${AGENT_HOST_VOLUME}
   echo "agentvolume= ${agentvolume}"
}

agent_name() {
   agentname=${AGENT_CONTAINER_NAME:-"OggVdtAgent"}
   echo "agentname= ${agentname}"
}

agent_port() {
   agentport=${AGENT_PORT:-7562}
   echo "agentport= ${agentport}"
}

agent_dir() {
   agentdir=${AGENT_DEPLOY_DIRECTORY:-"vdt_agent"}
   echo "agentdir= ${agentdir}"
}

agent_host
agent_name
agent_port
agent_dir

if [ "$version" == "" ]
then
  image_name="oracle/oggvdt:12.2.1.4.0"
  echo "WARNING !! Running $image_name . In case of version please run run_agent.sh {version}"
else
  image_name="oracle/oggvdt:12.2.1.4-$version"
fi

echo " docker run -d -p ${agentport}:${agentport} --env-file ${scriptDir}/vdtagent.env -e VERIDATA_AGENT=true -v ${agentvolume}:/u01/oracle/${agentdir} --name ${agentname}  --network=VdtBridge $image_name createOrStartVdtAgent.sh "

docker run -d -p ${agentport}:${agentport} --env-file ${scriptDir}/vdtagent.env -e VERIDATA_AGENT=true -v ${agentvolume}:/u01/oracle/${agentdir} --name ${agentname}  --network=VdtBridge $image_name createOrStartVdtAgent.sh
