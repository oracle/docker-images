#!/bin/sh
#
# Copyright (c) 2022 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Author: OIG Development
#
# Description: Script for management of agents
#
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

#Global Variables
containerRuntime=""
errorFlag=false
operation=""
newContainer=""
agentVersion=""

validateEmpty(){
    if [ "$1" = "" ];
     then
        errorFlag=true
        echo "ERROR: $2 is mandatory."
        echo "       Specify Using $3."
     else
       echo "INFO: Using $1 for $2."
  fi

}

createDir(){

   if [ ! -d "$1" ]
   then
     echo "ERROR: Volume directory $1 does not exist"
     exit 1;
   fi
  absoluteVolumePath=$(cd "$(dirname "$1")" || exit 1; pwd -P)/$(basename "$1")

  CONFDIR="$absoluteVolumePath"/data/conf;
  LOGSDIR="$absoluteVolumePath"/data/logs;
  WALLETDIR="$absoluteVolumePath"/data/wallet;
  AGENTDIR="$absoluteVolumePath"/data/agent;
  METRICSDIR="$absoluteVolumePath"/data/metrics;
  BUNDLEDIR="$absoluteVolumePath"/data/bundle-home;
  CUSTOMJARSDIR="$absoluteVolumePath"/data/customJars;

  if [ ! -d "$CONFDIR" ]
  then
    echo "INFO: Creating conf directory"
    mkdir -p  "$CONFDIR";
  fi

  if [ ! -d "$LOGSDIR" ]
  then
    echo "INFO: Creating logs directory"
    mkdir -p  "$LOGSDIR";
  fi

  if [ ! -d "$WALLETDIR" ]
  then
    echo "INFO: Creating wallet directory"
    mkdir -p  "$WALLETDIR";
  fi

  if [ ! -d "$AGENTDIR" ]
  then
    echo "INFO: Creating agent directory"
    mkdir -p  "$AGENTDIR";
  fi

  if [ ! -d "$METRICSDIR" ]
  then
    echo "INFO: Creating metrics directory"
    mkdir -p  "$METRICSDIR";
  fi

  if [ ! -d "$BUNDLEDIR" ]
  then
    echo "INFO: Creating bundle-home directory"
    mkdir -p  "$BUNDLEDIR";
  fi

  if [ ! -d "$CUSTOMJARSDIR" ]
    then
      echo "INFO: Creating custom driver jars directory"
      mkdir -p  "$CUSTOMJARSDIR";
  fi

  if [ -d "$absoluteVolumePath"/data ]
  then
      chmod -R 775 "$absoluteVolumePath"/data >/dev/null 2>&1
  fi


  ENV_FILE="$CONFDIR"/env.properties
  ENV_FILE_TEMP="$CONFDIR"/env_temp.properties

  touch "$ENV_FILE"
  rm -f "$ENV_FILE_TEMP"
  touch "$ENV_FILE_TEMP"
}

isDockerAvailable()
{
  if [ "$(docker --version 2>/dev/null)" ]
  then
    echo "INFO: Docker is available"
    echo "--------------------------------------------------"
    docker --version
    echo "--------------------------------------------------"
    containerRuntime="docker";
  fi
}

isPodmanAvailable()
{
  if [ "$(podman --version 2>/dev/null)" ]
  then
    echo "INFO: Podman is available"
    echo "--------------------------------------------------"
    podman --version
    echo "--------------------------------------------------"
    containerRuntime="podman";
  fi
}

detectJDKversion()
{
  javac -version
  if [ ! "$?" ]
   then
     echo "ERROR: JDK is not installed. Please install JDK 11"
     errorFlag=true
     return
  fi
  javaVersion=$(javac -version 2>&1 | awk '{ print $2 }' | cut -d'.' -f1)
  if [ "$javaVersion" != "11" ]
   then
     echo "ERROR: JDK 11 is required"
     errorFlag=true
  fi
}

detectContainerRuntime()
{
  echo "INFO: Detecting Container Runtime"
  isPodmanAvailable
  if [ -z "$containerRuntime" ] && [ "$containerRuntime" = "" ]
  then
    isDockerAvailable
  fi

  if [ -z "$containerRuntime" ] && [ "$containerRuntime" = "" ]
  then
    echo "ERROR: No container runtime available. Please install Docker/Podman before proceeding"
    errorFlag=true
    return
  fi
  echo "INFO: Using $containerRuntime Container Runtime"
  echo containerRuntime=$containerRuntime >> "$ENV_FILE_TEMP"
}

# shellcheck source=/dev/null
copyAndUnzipAgentPackage()
{
  . "$ENV_FILE_TEMP"
   rm -rf "$AGENTDIR:?"/*
   unzip "$AP" -d "$AGENTDIR"
}

copyConfigOverride(){
   if [ -f  "$configOverride" ]
  then
    cp -f "$configOverride"  "$CONFDIR"/config.properties
  fi
}

# shellcheck source=/dev/null
copyConfig(){
  echo "INFO: Copying wallet and config.json"
  . "$ENV_FILE_TEMP"
  CONFFILE="$CONFDIR"/config.json
  WALLETFILE="$WALLETDIR"/cwallet.sso
  WALLETLOCKFILE="$WALLETDIR"/cwallet.sso.lck

  if [ ! -f  "$CONFFILE" ]
   then
    cp -r "$AGENTDIR"/config.json  "$CONFDIR"
  else
    echo "INFO: Config.json already exists"
  fi

  if [ ! -f  "$WALLETFILE" ]
  then
    cp -r "$AGENTDIR"/wallet/cwallet.sso  "$WALLETDIR"
  else
    echo "INFO: Wallet already exists"
  fi

  if [ ! -f  "$WALLETLOCKFILE" ]
  then
    cp -r "$AGENTDIR"/wallet/cwallet.sso.lck  "$WALLETDIR"
  fi

}

# shellcheck source=/dev/null
setupConfig(){

. "$ENV_FILE"
echo "INFO: Setting up Configuration"
if [ "${AI}" = "" ];
 then
   AI=agent_"$(hostname -f)"_"$(date +%s)"
   echo AI=agent_"$(hostname -f)"_"$(date +%s)" >> "$ENV_FILE_TEMP"
fi

if [ "${AU}" = "" ];
 then
   AU=true
   echo AU=true >> "$ENV_FILE_TEMP"
fi

# shellcheck disable=SC3010,SC3028
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i "" -e "s/__AGENT_ID__/${AI}/g" "$CONFDIR"/config.json
else
  sed -i -e "s/__AGENT_ID__/${AI}/g" "$CONFDIR"/config.json
fi

}

loadImage(){
  echo "INFO: Loading container image. It may take some time."
  imageName=""
  if [ "$containerRuntime" = "docker" ]
  then
    imageName=$(docker load < "$AGENTDIR"/agent-lcm/idm-agcs-agent-framework.dockerize_agent.tar.gz | grep "Loaded image" | awk '{ print $3 }')
  elif [ "$containerRuntime" = "podman" ]
  then
    imageName=$(podman load < "$AGENTDIR"/agent-lcm/idm-agcs-agent-framework.dockerize_agent.tar.gz | grep "Loaded image" | awk '{ print $3 }')
  fi
  if [ "$imageName" = "" ]
  then
    echo "ABORTED: Unable to load the image."
    exit 1;
  fi
  echo imageName="$imageName" >> "$ENV_FILE_TEMP"
}

# shellcheck source=/dev/null
runAgent(){
   groupId=$(id -g)
   . "$ENV_FILE"
   if [ "$containerRuntime" = "docker" ]
   then
      if [ ! "$(docker ps -a -f "name=$AI" --format '{{.Names}}')" ]
      then
         echo "INFO: Starting new container."
          if [ -f "$CONFDIR"/config.properties ]; then
              docker run -d --env-file "$CONFDIR"/config.properties -v "$PV":/app --group-add "$groupId" --name "$AI"  "$imageName"
          else
              docker run -d -v "$PV":/app --group-add "$groupId" --name "$AI"  "$imageName"
          fi
         docker exec "$AI" /bin/bash -c 'agent ido validate --config /app/data/conf/config.json; if [[ "$?" != "0" ]] ; then echo VALIDATE_FAILED > /app/data/conf/status.txt; else echo VALIDATE_SUCCESS > /app/data/conf/status.txt; fi ;'
          validateStatus=$(cat "$CONFDIR"/status.txt)
          if [ "$validateStatus" = "VALIDATE_FAILED" ]
          then
           echo "ERROR: Agent Validation Failed. Exiting"
           docker rm -f "$AI"
           exit 1;
          fi
          if [ ! "$operation" = "upgrade" ]
           then
             docker exec "$AI" /bin/bash -c "agent ido start --config /app/data/conf/config.json &"
          fi

      elif [ ! "$(docker ps -f "name=$AI" --format '{{.Names}}')" ]
      then
         echo "INFO: Starting existing container $AI "
         docker start "$AI"
         docker exec "$AI" /bin/bash -c 'agent ido validate --config /app/data/conf/config.json; if [[ "$?" != "0" ]] ; then echo VALIDATE_FAILED > /app/data/conf/status.txt; else echo VALIDATE_SUCCESS > /app/data/conf/status.txt; fi ;'
          validateStatus=$(cat "$CONFDIR"/status.txt)
          if [ "$validateStatus" = "VALIDATE_FAILED" ]
          then
           echo "ERROR: Agent Validation Failed. Exiting"
           docker rm -f "$AI"
           exit 1;
          fi
          if [ ! "$operation" = "upgrade" ]
           then
             docker exec "$AI" /bin/bash -c 'agent ido start --config /app/data/conf/config.json &'
          fi
      else
         echo "WARN: Agent is already running"
      fi
      # removing older image in case of upgrade
      if [ "$operation" = "postUpgrade" ]
       then
         echo "INFO: Removing older image ${installedImageName}"
         docker image rm "${installedImageName}" || true
      fi
  elif [ "$containerRuntime" = "podman" ]
  then
      if [ ! "$(podman ps -a -f "name=$AI" --format '{{.Names}}')" ]
      then
         echo "INFO: Starting new container."
          if [ -f "$CONFDIR"/config.properties ]; then
            podman run -d --user root --env-file "$CONFDIR"/config.properties -v "$PV":/app --group-add "$groupId" --name "$AI"  "$imageName"
          else
            podman run -d --user root -v "$PV":/app --group-add "$groupId" --name "$AI"  "$imageName"
          fi

         podman exec "$AI" /bin/bash -c 'agent ido validate --config /app/data/conf/config.json; if [[ "$?" != "0" ]] ; then echo VALIDATE_FAILED > /app/data/conf/status.txt; else echo VALIDATE_SUCCESS > /app/data/conf/status.txt; fi ;'
          validateStatus=$(cat "$CONFDIR"/status.txt)
          if [ "$validateStatus" = "VALIDATE_FAILED" ]
          then
           echo "ERROR: Agent Validation Failed. Exiting"
           podman rm -f "$AI"
           exit 1;
          fi
          if [ ! "$operation" = "upgrade" ]
           then
             podman exec "$AI" /bin/bash -c "agent ido start --config /app/data/conf/config.json &"
          fi

      elif [ ! "$(podman ps -f "name=$AI" --format '{{.Names}}')" ]
      then
         echo "INFO: Starting existing container $AI "
         podman start "$AI"
         podman exec "$AI" /bin/bash -c 'agent ido validate --config /app/data/conf/config.json; if [[ "$?" != "0" ]] ; then echo VALIDATE_FAILED > /app/data/conf/status.txt; else echo VALIDATE_SUCCESS > /app/data/conf/status.txt; fi ;'
          validateStatus=$(cat "$CONFDIR"/status.txt)
          if [ "$validateStatus" = "VALIDATE_FAILED" ]
          then
           echo "ERROR: Agent Validation Failed. Exiting"
           podman rm -f "$AI"
           exit 1;
          fi
          if [ ! "$operation" = "upgrade" ]
           then
             podman exec "$AI" /bin/bash -c "agent ido start --config /app/data/conf/config.json &"
          fi

      else
         echo "WARN: Agent is already running"
      fi
      # removing older image in case of upgrade
      if [ "$operation" = "postUpgrade" ]
       then
         echo "INFO: Removing older image ${installedImageName} "
         podman image rm "${installedImageName}" || true
      fi
  fi
}

hasDockerPermissions()
{
  echo ""
}

isWriteAccessOnVolume()
{
  # shellcheck disable=SC2012
  permissions=$(ls -ld "$PV" | awk '{print $1}')
  # shellcheck disable=SC3057
  perms="${permissions:0:10}"
  if [ "$perms" != "drwxrwxr-x" ] && [ "$perms" != "drwxrwxrwx" ]; then
    echo "ERROR: Volume does not have required permissions. Make sure to have 775"
    errorFlag=true
  fi
}

validate()
{
  echo "Validating Agent"
}

info(){
  agentImageVersion=$(echo "$imageName" | cut -d':' -f2)
  echo "Agent Id           : $AI"

  if [ "$containerRuntime" = "docker" ]
  then
      echo "Container Runtime  : $(docker --version)"
  elif [ "$containerRuntime" = "podman" ]
  then
      echo "Container Runtime  : $(podman --version)"
  fi
  echo "Install Location   : $PV"
  echo "Agent Package used : $AP"
  echo "Agent Version      : $agentImageVersion"
  echo "Logs directory     : ${PV}/data/logs"

}

agentDaemonStatus(){
  validateStatus=$(cat "$CONFDIR"/status.txt)
  if [ "$validateStatus" = "AGENT_RUNNING_NORMALLY" ]
  then
   echo "Agent Status       : Running normally"
  elif [ "$validateStatus" = "AGENT_SHUTDOWN_IN_PROGRESS" ]; then
      echo "Agent Status       : Shutdown is in Progress"
  else
    echo "Agent Status       : Stopped"
  fi
}

# shellcheck source=/dev/null
status(){
  errorFlag=false
  if [ -f "$ENV_FILE" ]
   then
     . "$ENV_FILE"
  fi
  validateEmpty "${PV}" "Volume" "--volume"
  isAgentAvailable
  if [ $errorFlag = "true" ]; then
           echo "Agent is not installed."
           exit 1
  fi
  info
  if [ "$containerRuntime" = "docker" ]
   then
      if [ "$(docker ps -f "name=$AI" --format '{{.Names}}')" ]
      then
        docker exec "$AI" /bin/bash -c 'agent --config /app/data/conf/config.json ido lcm -i status_check; if [[ "$?" == "0" ]] ; then echo AGENT_RUNNING_NORMALLY > /app/data/conf/status.txt; elif [[ "$?" == "1" ]] ; then echo AGENT_SHUTDOWN_IN_PROGRESS > /app/data/conf/status.txt; else echo AGENT_SHUTDOWN > /app/data/conf/status.txt; fi ;' >/dev/null
        agentDaemonStatus
      else
         echo "Agent Status       : Container not running"
      fi
  elif [ "$containerRuntime" = "podman" ]
  then
      if [ "$(podman ps -f "name=$AI" --format '{{.Names}}')" ]
      then
         podman exec "$AI" /bin/bash -c 'agent --config /app/data/conf/config.json ido lcm -i status_check; if [[ "$?" == "0" ]] ; then echo AGENT_RUNNING_NORMALLY > /app/data/conf/status.txt; elif [[ "$?" == "1" ]] ; then echo AGENT_SHUTDOWN_IN_PROGRESS > /app/data/conf/status.txt; else echo AGENT_SHUTDOWN > /app/data/conf/status.txt; fi ;' >/dev/null
         agentDaemonStatus
      else
         echo "Agent Status       : Container not running"
      fi
  fi
}

# shellcheck source=/dev/null
setproxy(){
  # new/user provided configuration is stored in ENV_FILE_TEMP so sourcing it first
  . "$ENV_FILE"
  . "$ENV_FILE_TEMP"
  echo "INFO: Setting proxy"

  # Set proxy params in config.json

  # in the end replace proxy parms in the env.properties(Source of truth)
}

isAlreadyInstalled(){
# shellcheck disable=SC2154
 if [ "$isInstallSuccess" = "true" ] && [ ! "$operation" = "upgrade" ]
  then
    echo "INFO: Agent is already installed with agent id ${AI} "
    errorFlag=true
 fi
}

isAgentAvailable(){
  if [ "$isInstallSuccess" = "true" ]
  then
    echo "INFO: Agent with agent id ${AI} is available."
  else
    errorFlag=true
 fi
}

getProperty() {
   PROP_KEY=$1
# shellcheck disable=SC2002
   PROP_VALUE=$(cat "$CONFDIR"/config.properties | grep "$PROP_KEY" | cut -d'=' -f2)
   echo "$PROP_VALUE"
}

fetchAgentContainerImage(){

  echo "INFO: Fetching Agent Container Image"
  proxyUri=""
  proxyUserName=""
  proxyUserPassword=""
  if [ -f "$CONFDIR"/config.properties ]; then
    echo "INFO: Getting Proxy settings"
    proxyUri=$(getProperty idoConfig.httpClientConfiguration.proxyUri)
    proxyUserName=$(getProperty idoConfig.httpClientConfiguration.proxyUserName)
    proxyUserPassword=$(getProperty idoConfig.httpClientConfiguration.proxyUserPassword)
  fi
  agentVersion=$(unzip -q -c  "$AGENTDIR"/agent-lcm/idm-agcs-agent-lcm.jar META-INF/MANIFEST.MF | grep "Agent-Version: " | awk '{print $2}' | tr -d '\n' | tr -d '\r')
  java -jar "$AGENTDIR"/agent-lcm/idm-agcs-agent-lcm.jar install -w "$WALLETDIR" -d "$AGENTDIR"/agent-lcm/ -ph "$proxyUri" -pu "$proxyUserName" -pp "$proxyUserPassword" -v "$agentVersion"
  if [ -f "$AGENTDIR"/agent-lcm/"$agentVersion"/idm-agcs-agent-framework.dockerize_agent.tar.gz ]; then
      mv "$AGENTDIR"/agent-lcm/"$agentVersion"/idm-agcs-agent-framework.dockerize_agent.tar.gz "$AGENTDIR"/agent-lcm/
      echo "INFO: Successfully fetched the Agent Container Image"
  else
    echo "ERROR: Unable to fetch the Agent Container Image"
    exit 1
  fi
}

isValidChecksum()
{
  echo "INFO: Verifying Integrity Check"
  java -jar "$AGENTDIR"/agent-lcm/idm-agcs-agent-lcm.jar validateIntegrity -w "$WALLETDIR" -p "$AGENTDIR"/agent-lcm/idm-agcs-agent-framework.dockerize_agent.tar.gz
  if [ ! "$?" ]
   then
     echo "ERROR: Integrity Check Verification failed."
     exit 1
  fi
}

# shellcheck source=/dev/null
install()
{
  if [ -f "$ENV_FILE_TEMP" ]
   then
     . "$ENV_FILE_TEMP"
  fi

  if [ -f "$ENV_FILE" ]
   then
     . "$ENV_FILE"
  fi

  validateEmpty "${AP}" "Agent Package" "--agentpackage"
  validateEmpty "${PV}" "Volume" "--volume"
  if [ ! -f "${AP}" ]
   then
     echo "ERROR: Agent Package does not exist"
     exit 1;
  fi
  if [ ! -d "${PV}" ]
   then
     echo "ERROR: Volume directory does not exist"
     exit 1;
  fi
  #Pre-requiste Validations
  isAlreadyInstalled
  detectJDKversion
  isWriteAccessOnVolume
  detectContainerRuntime
  if [ $errorFlag = "true" ]; then
           echo "ABORTED: Please rectify the errors. Use -h/--help option for help"
           exit 1
  fi
  copyAndUnzipAgentPackage
  copyConfig
  copyConfigOverride
  setupConfig
  fetchAgentContainerImage
  isValidChecksum
  loadImage
  if [ "$AU" = "true" ]
     then
       enableAutoUpgrade
  fi
  echo "INFO: Agent installed successfully. You can start the agent now."
  echo "isInstallSuccess=true" >> "$ENV_FILE_TEMP"
  cp "$ENV_FILE_TEMP" "$ENV_FILE"
}

# shellcheck source=/dev/null
enableAutoUpgrade(){

  if [ -f "$ENV_FILE_TEMP" ]
     then
       . "$ENV_FILE_TEMP"
  fi

  if [ -f "$ENV_FILE" ]
     then
       . "$ENV_FILE"
  fi
  validateEmpty "${PV}" "Volume" "--volume"
  detectJDKversion

  if [ $errorFlag = "true" ]; then
             echo "ABORTED: Please rectify the errors. Use -h/--help option for help"
             exit 1
  fi
  crontab -l > autoupdatercron
  alreadyExists=$(grep -rnw autoupdatercron -e "${AI}")
  if [ "" != "${alreadyExists}" ]
     then
      echo "INFO: Auto Upgrade for the agent with id ${AI} already exists. "
     else
      echo "INFO: Setting Up Auto Upgrade of the agent with id ${AI}. "
      javaPath=$(which java | rev | cut -c6- | rev)
      # shellcheck disable=SC2002
      proxyUri=$(cat "$PV"/data/conf/config.properties | grep "idoConfig.httpClientConfiguration.proxyUri" | cut -d'=' -f2)
      echo "INFO: Proxy URL is ${proxyUri}"
      if [ "${proxyUri}" != "" ]
       then
         echo "*/30 * * * * export HTTPS_PROXY=${proxyUri};export https_proxy=${proxyUri};export PATH=${javaPath}:$PATH;curl https://raw.githubusercontent.com/oracle/docker-images/main/OracleIdentityGovernance/samples/scripts/agentAutoUpdate.sh -o ${PV}/agentAutoUpdate.sh;sh ${PV}/agentAutoUpdate.sh ${PV} ${AI} " >> autoupdatercron
       else
         echo "*/30 * * * * export PATH=${javaPath}:$PATH;curl https://raw.githubusercontent.com/oracle/docker-images/main/OracleIdentityGovernance/samples/scripts/agentAutoUpdate.sh -o ${PV}/agentAutoUpdate.sh;sh ${PV}/agentAutoUpdate.sh ${PV} ${AI} " >> autoupdatercron
      fi
      crontab autoupdatercron
      rm autoupdatercron
      currentCron=$(crontab -l)
      if [ "" = "${currentCron}" ]
         then
           echo "INFO: No cron exists. Please try again."
         else
           echo "INFO: List of the current cron tabs"
           echo "${currentCron}"
           echo "INFO: Successfully Set Up Auto Upgrade of the agent with id ${AI}."
      fi
  fi
}

# shellcheck source=/dev/null
autoUpgrade(){
  if [ -f "$ENV_FILE_TEMP" ]
     then
       . "$ENV_FILE_TEMP"
  fi

  if [ -f "$ENV_FILE" ]
     then
       . "$ENV_FILE"
  fi
  validateEmpty "${PV}" "Volume" "--volume"
  detectJDKversion

  if [ $errorFlag = "true" ]; then
             echo "ABORTED: Please rectify the errors. Use -h/--help option for help"
             exit 1
  fi
  curl https://raw.githubusercontent.com/oracle/docker-images/main/OracleIdentityGovernance/samples/scripts/agentAutoUpdate.sh -o "${PV}"/agentAutoUpdate.sh;sh "${PV}"/agentAutoUpdate.sh "${PV}" "${AI}"
}

# shellcheck source=/dev/null
disableAutoUpgrade(){
  if [ -f "$ENV_FILE_TEMP" ]
       then
         . "$ENV_FILE_TEMP"
  fi

  if [ -f "$ENV_FILE" ]
       then
         . "$ENV_FILE"
  fi
  validateEmpty "${PV}" "Volume" "--volume"
  if [ $errorFlag = "true" ]; then
             echo "ABORTED: Please rectify the errors. Use -h/--help option for help"
             exit 1
  fi
  crontab -l > autoupdatercron
  ifExists=$(grep -rnw autoupdatercron -e "${AI}")
    if [ "" = "${ifExists}" ]
       then
        echo "INFO: Auto Upgrade for the agent with id ${AI} does not exist. "
       else
        echo "INFO: Removing Auto Upgrade of the agent with id ${AI}. "
        crontab -l | grep -v "${AI}"  | crontab -
        rm autoupdatercron
        currentCron=$(crontab -l)
        if [ "" = "${currentCron}" ]
           then
             echo "INFO: No cron exists now."
           else
             echo "${currentCron}"
        fi
        echo "INFO: Successfully Removed Auto Upgrade of the agent with id ${AI}."
    fi
}

# shellcheck source=/dev/null
start()
{
  if [ -f "$ENV_FILE" ]
   then
     . "$ENV_FILE"
  fi
  validateEmpty "${PV}" "Volume" "--volume"
  if [ $errorFlag = "true" ]; then
           echo "ABORTED: Please rectify the errors. Use -h/--help option for help"
           exit 1
  fi
  echo "INFO: Starting Agent"
  copyConfigOverride
  if [ -f "$configOverride" ]; then
   kill
  fi
  runAgent
  echo ""
  info
  echo ""
  echo "INFO: Logs directory: ${PV}/data/logs"
  echo "INFO: You can monitor the agent ${AI} from the Access Governance Console."
}

list_descendants ()
{
  # shellcheck disable=SC3043,SC2155,SC2046
  local children=$(ps -o pid= --ppid "$1")

  for pid in $children
  do
    list_descendants "$pid"
  done

  echo "$children"
}

forceStopPodman()
{
# Get the main process for the container.
CONTAINER_ID=$(podman ps | grep "$AI" | awk '{print $1}')
if [ -n "${CONTAINER_ID}" ]; then
   echo Container ID : "$CONTAINER_ID"
   CONTAINER_PROCESS_ID=$(ps -ef | grep -v grep | grep "$CONTAINER_ID" | awk '{print $2}')
   echo Container Process ID: ${CONTAINER_PROCESS_ID}

   # shellcheck disable=SC2046
   kill -9 $(list_descendants ${CONTAINER_PROCESS_ID})
   
   # Kill any processes containing the process ID.
   # This kills the child processes too.
   # shellcheck disable=SC2046
   kill -9 `ps -ef | grep -v grep | grep ${CONTAINER_PROCESS_ID} | awk '{print $2}'`

   # Stop the container, as Podman doesn't notice the processes are dead until you interact with the container.
   echo "Stop container. Ignore errors."
   podman stop "$AI"
else
   echo "Container Already Stopped" 
fi
}

forceRmPodman()
{
# Get the main process for the container.
CONTAINER_ID=$(podman ps -a | grep "$AI" | awk '{print $1}')
if [ -n "${CONTAINER_ID}" ]; then
   echo Container ID : "$CONTAINER_ID"
   CONTAINER_PROCESS_ID=$(ps -ef | grep -v grep | grep "$CONTAINER_ID" | awk '{print $2}')
   echo Container Process ID: ${CONTAINER_PROCESS_ID}

   # shellcheck disable=SC2046
   kill -9 $(list_descendants ${CONTAINER_PROCESS_ID})
   
   # Kill any processes containing the process ID.
   # This kills the child processes too.
   # shellcheck disable=SC2046
   kill -9 `ps -ef | grep -v grep | grep ${CONTAINER_PROCESS_ID} | awk '{print $2}'`

   # Stop the container, as Podman doesn't notice the processes are dead until you interact with the container.
   echo "Removing container. Ignore errors."
   podman rm -f "$AI"
else
   echo "Container Already Removed"
fi
}

# shellcheck source=/dev/null
stop()
{
  echo "INFO: Gracefully Stopping Agent"
  if [ -f "$ENV_FILE" ]
   then
     . "$ENV_FILE"
  fi
  validateEmpty "${PV}" "Volume" "--volume"
  if [ $errorFlag = "true" ]; then
           echo "ABORTED: Please rectify the errors. Use -h/--help option for help"
           exit 1
  fi
  if [ "$containerRuntime" = "docker" ]
  then
      docker exec "$AI" /bin/bash -c "agent --config /app/data/conf/config.json ido lcm -i graceful_shutdown;"
      echo "INFO: Waiting for running operations to complete. It may take some time"
      docker exec "$AI" /bin/bash -c 'agent --config /app/data/conf/config.json ido lcm -i status_check; while [[ "$?" != "2" && "$?" != "255" ]]; do sleep 5s;agent --config /app/data/conf/config.json ido lcm -i status_check; done' >/dev/null
      docker stop "$AI"
  elif [ "$containerRuntime" = "podman" ]
  then
      podman exec "$AI" /bin/bash -c "agent --config /app/data/conf/config.json ido lcm -i graceful_shutdown;"
      echo "INFO: Waiting for running operations to complete. It may take some time"
      podman exec "$AI" /bin/bash -c 'agent --config /app/data/conf/config.json ido lcm -i status_check; while [[ "$?" != "2" && "$?" != "255" ]]; do sleep 5s;agent --config /app/data/conf/config.json ido lcm -i status_check; done' >/dev/null
      podman stop "$AI"
      forceStopPodman
  fi
  echo "INFO: Agent Stopped"
}

# shellcheck source=/dev/null
kill()
{
  if [ -f "$ENV_FILE" ]
   then
     . "$ENV_FILE"
  fi
  validateEmpty "${PV}" "Volume" "--volume"
  if [ $errorFlag = "true" ]; then
           echo "ABORTED: Please rectify the errors. Use -h/--help option for help"
           exit 1
  fi
  if [ "$containerRuntime" = "docker" ] && [ "$(docker ps -a -f "name=$AI" --format '{{.Names}}')" ]
  then

      if [ ! "$operation" = "upgrade" ] && [ ! "$operation" = "postUpgrade" ]
      then
        docker exec "$AI" /bin/bash -c "agent --config /app/data/conf/config.json ido lcm -i graceful_shutdown;"
        echo "INFO: Waiting for running operations to complete. It may take some time"
        docker exec "$AI" /bin/bash -c 'agent --config /app/data/conf/config.json ido lcm -i status_check; while [[ "$?" != "2" && "$?" != "255" ]]; do sleep 5s;agent --config /app/data/conf/config.json ido lcm -i status_check; done' >/dev/null
      fi
      docker rm -f "$AI"
  elif [ "$containerRuntime" = "podman" ] && [ "$(podman ps -a -f "name=$AI" --format '{{.Names}}')" ]
  then
      if [ ! "$operation" = "upgrade" ] && [ ! "$operation" = "postUpgrade" ]
      then
        podman exec "$AI" /bin/bash -c "agent --config /app/data/conf/config.json ido lcm -i graceful_shutdown;"
        echo "INFO: Waiting for running operations to complete. It may take some time"
        podman exec "$AI" /bin/bash -c 'agent --config /app/data/conf/config.json ido lcm -i status_check; while [[ "$?" != "2" && "$?" != "255" ]]; do sleep 5s;agent --config /app/data/conf/config.json ido lcm -i status_check; done' >/dev/null
      fi
      podman rm -f "$AI"
      forceRmPodman
  fi
}

createBackup(){
  echo "INFO: Backing up the previous agent"
  rm -rf "${PV}"/backup
  mkdir -p "${PV}"/backup
  cp -rf "${PV}"/data "${PV}"/backup
}

restoreBackup(){
  echo "INFO: Restoring backup"
  #copying all the files from the backup dir to the volume
  cp -rf "${PV}"/backup "${PV}"
}

# shellcheck source=/dev/null
upgrade()
{
  if [ -f "$ENV_FILE_TEMP" ]
   then
     . "$ENV_FILE_TEMP"
  fi
  #validate mandatory fields
  validateEmpty "${AP}" "New Agent Package" "--agentpackage"
  validateEmpty "${PV}" "Volume" "--volume"
  if [ $errorFlag = "true" ]; then
           echo "ABORTED: Please rectify the errors. Use -h/--help option for help"
           exit 1
  fi

  if [ ! "${AI}" = "" ]
   then
     echo "WARN: Ignoring Agent Id ${AI} "
  fi

  #store the new agent package into a variable
  newAgentPackage="${AP}"

  . "$ENV_FILE" #older config file
  isAgentAvailable
  if [ $errorFlag = "true" ]; then
           echo "ABORTED: Agent is not installed."
           rm -rf "$PV/data"
           rm -rf "$PV/upgrade"
           rm -rf "$PV/backup"
           exit 1
  fi

  echo "INFO: Upgrading Agent with id ${AI} "
  installedPV="${PV}"
  installedAgentId="${AI}"
  installedImageName="${imageName}"
  #generate a new agent id for upgrade using old agent id
  AI="${installedAgentId}"_upgrade
  newAgentId=${AI}

  #createDir changes the current working directory
  mkdir -p "${PV}/upgrade"
  chmod -R 775 "${PV}/upgrade" >/dev/null 2>&1

  createDir "${PV}/upgrade"
# shellcheck disable=SC2129
  echo AP="${newAgentPackage}" >> "$ENV_FILE_TEMP"
  echo PV="${PV}"/upgrade >> "$ENV_FILE_TEMP"
  echo AI="${AI}" >> "$ENV_FILE_TEMP"

  #install the upgrade
  operation=upgrade
  # Following copies the customJars from the install location to the upgrade directory
  if [ -d "${installedPV}/data/customJars" ]
   then
     if [ "$(ls -A "${installedPV}/data/customJars")" ]
        then
          echo "INFO: Copying custom jars"
          cp -rf "${installedPV}/data/customJars" "${PV}/upgrade/data"
    fi
  fi

  install
  #install also loads the image, so we can get the new image here
  newimage="${imageName}"
  echo "INFO: Starting test upgrade agent"
  start
  echo "INFO: Test Upgrade is successful"
  kill
  #remove the crontab from upgrade
  crontab -l | grep -v "${AI}"  | crontab -

  #change to the installed directory, this sets the ENV_FILE to the older config
  createDir "${installedPV}"
  # sourcing installed config to kill the older container
  operation=postUpgrade
  . "$ENV_FILE"
  createBackup
  echo "INFO: Removing the old agent"
  kill
  #removing the cron of older agent
  crontab -l | grep -v "${AI}"  | crontab -

  echo "INFO: Copying new wallet"
  cp -rf "${PV}/upgrade/data/wallet" "${PV}"/data

  cp -rf "${PV}/upgrade/data/agent" "${PV}"/data

  echo "INFO: Copying new configuration"
  cp -f "${PV}/upgrade/data/conf/config.json" "$CONFDIR"

  if [ -f "${PV}/upgrade/data/conf/config.properties" ]
  then
      cp -f "${PV}/upgrade/data/conf/config.properties" "$CONFDIR"
  fi

  sed -i "" -e "s/${newAgentId}/${installedAgentId}/g" "$CONFDIR"/config.json


  #use the older agent id
  awk -F"=" -v OFS='=' -v  newval="$installedAgentId" '/^AI/{$2=newval;print;next}1' "$ENV_FILE" > "$ENV_FILE_TEMP"
  cp -f "$ENV_FILE_TEMP" "$ENV_FILE"
  awk -F"=" -v OFS='=' -v  newval="$newAgentPackage" '/^AP/{$2=newval;print;next}1' "$ENV_FILE" > "$ENV_FILE_TEMP"
  cp -f "$ENV_FILE_TEMP" "$ENV_FILE"
  awk -F"=" -v OFS='=' -v  newval="$newimage" '/^imageName/{$2=newval;print;next}1' "$ENV_FILE" > "$ENV_FILE_TEMP"
  cp -f "$ENV_FILE_TEMP" "$ENV_FILE"

  start
  crontab -l > autoupdatercron
  alreadyExists=$(grep -rnw autoupdatercron -e "${AI}")
  if [ "" != "${alreadyExists}" ]
     then
      echo "INFO: Auto Upgrade for the agent with id ${AI} is already setup. "
     else
      echo "INFO: Setting Up Auto Upgrade of the agent with id ${AI}. "
      javaPath=$(which java | rev | cut -c6- | rev)
      # shellcheck disable=SC2002
      proxyUri=$(cat "$PV"/data/conf/config.properties | grep "idoConfig.httpClientConfiguration.proxyUri" | cut -d'=' -f2)
      echo "INFO: Proxy URL is ${proxyUri}"
      if [ "${proxyUri}" != "" ]
       then
         echo "*/30 * * * * export HTTPS_PROXY=${proxyUri};export https_proxy=${proxyUri};export PATH=${javaPath}:$PATH;curl https://raw.githubusercontent.com/oracle/docker-images/main/OracleIdentityGovernance/samples/scripts/agentAutoUpdate.sh -o ${PV}/agentAutoUpdate.sh;sh ${PV}/agentAutoUpdate.sh ${PV} ${AI} " >> autoupdatercron
       else
         echo "*/30 * * * * export PATH=${javaPath}:$PATH;curl https://raw.githubusercontent.com/oracle/docker-images/main/OracleIdentityGovernance/samples/scripts/agentAutoUpdate.sh -o ${PV}/agentAutoUpdate.sh;sh ${PV}/agentAutoUpdate.sh ${PV} ${AI} " >> autoupdatercron
      fi
      crontab autoupdatercron
      rm autoupdatercron
      currentCron=$(crontab -l)
      if [ "" = "${currentCron}" ]
         then
           echo "INFO: No cron exists. Please try again."
         else
           echo "INFO: List of the current cron tabs"
           echo "${currentCron}"
           echo "INFO: Successfully Set Up Auto Upgrade of the agent with id ${AI}."
      fi
  fi
  rm -rf "${PV}/upgrade"
}

restart()
{
  echo "INFO: Restarting Agent"
  if [ "$newContainer" = "true" ]
   then
     echo "WARN: This will remove the existing agent container and start a new one."
     echo "Are you sure to continue? [y/N]"
     read -r input
     if [ "$input" = "y" ] || [ "$input" = "Y" ]
      then
        kill
      else
        echo "ABORTED: Restart"
        exit 1;
     fi
   else
    stop
  fi
  start
}

# shellcheck source=/dev/null
uninstall(){

  echo "WARN: This will remove the existing agent and clean up the install directory."
  echo "Are you sure to continue? [y/N]"
  read -r input
   if [ ! "$input" = "y" ] && [ ! "$input" = "Y" ]
    then
      exit 1;
   fi
  if [ -f "$ENV_FILE" ]
   then
     . "$ENV_FILE"
  fi
  isAgentAvailable
  if [ $errorFlag = "true" ]; then
           echo "ABORTED: Agent is not installed."
           exit 1
  fi
  echo "INFO: Uninstalling Agent"
  kill
  disableAutoUpgrade
  if [ -d "${PV}" ]
   then
    echo "INFO: Removing agent data from ${PV}  "
    rm -rf "${PV}/data"
    rm -rf "${PV}/upgrade"
    rm -rf "${PV}/backup"
    echo "INFO: Agent uninstalled successfully"
  fi
}

# shellcheck source=/dev/null
rename(){
  . "$ENV_FILE_TEMP"
  validateEmpty "${AI}" "Agent Id" "--agentid"
  if [ $errorFlag = "true" ]; then
           echo "ABORTED: Please rectify the errors. Use -h/--help option for help"
           exit 1
  fi

  newAgentId="${AI}"
  . "$ENV_FILE"

  if [ "$containerRuntime" = "docker" ]
  then
    if [ "$(docker ps -a -f "name=$AI" --format '{{.Names}}')" ]
     then
     echo "INFO: Renaming Agent"
     docker rename "${AI}" "${newAgentId}"
   else
     echo "INFO: No Container with the name ${AI} is available to rename"
     exit 1
   fi
  elif [ "$containerRuntime" = "podman" ]
  then
    if [ "$(podman ps -a -f "name=$AI" --format '{{.Names}}')" ]
     then
     echo "INFO: Renaming Agent"
     podman rename "${AI}" "${newAgentId}"
   else
     echo "INFO: No Container with the name ${AI} is available to rename"
     exit 1
   fi
  fi
  awk -F"=" -v OFS='=' -v  newval="$newAgentId" '/^AI/{$2=newval;print;next}1' "$ENV_FILE" > "$ENV_FILE_TEMP"
  cp "$ENV_FILE_TEMP" "$ENV_FILE"
}


################################################################################
# Help                                                                         #
################################################################################
Help()
{
   # Display Help
   echo "Access Governance - Agent Management Script "
   echo
   echo "Syntax: ./agentManagement.sh --volume <volume> [config] [operation]"
   echo
   echo "Config                 Mandatory                               Default Value                     Description"
   echo "------                 ---------                               -------------                     -----------"
   echo "-ai|--agentid          No                                      agent_<hostname>_<timestamp>      Agent Id of the container"
   echo "-ap|--agentpackage     No(Required in validate,install
                       and upgrade)                            \"\"                                Agent Package Path"
   echo "-c|--config            No                                      -                                 Path of the custom config property file"
   echo "-pv|--volume           Yes                                     -                                 Directory to persist agent data such as
                                                                                                 configuration, wallet, logs, etc."

   echo

   echo "Operation              Description"
   echo "---------              -----------"
   echo ""
   echo "--install              1. Installs the agent package to the specified volume
                       2. Loads the container image "
   echo ""
   echo "--start                1. Starts the agent container
                       2. Starts the agent daemon"
   echo "--setupautoupgrade     1. Setup Auto Upgrade of the agent"
   echo ""
   echo "--status               1. Displays the status of the agent"
   echo ""
   echo "--stop                 1. Stops the agent daemon
                       2. Stops the agent container"
   echo ""
   echo "--restart              1. Stops the agent daemon
                       2. Stops the agent container
                       3. remove the agent container if \"newcontainer\" flag is set
                       4. Starts the agent container
                       5. Starts the agent daemon"
   echo "                       Provide --newcontainer to create a new container"

   echo ""
   echo "--uninstall            1. Stops the agent daemon
                       2. Remove the agent container
                       3. Cleanup the volume"
   echo ""
   echo "--upgrade              1. Unzips the new agent-package.zip in a temporary location
                       2. Validates the contents
                       3. Loads image from the new tar.gz
                       4. Brings up a temporary container using the new image and the new configuration
                       4. If successful then stop the temporary container
                       5. Stop the existing agent container
                       6. Copy the new config from the temporary location to the main location keeping the customizations
                       7. Start the agent with the new image and the new config
                       8. Spin up the agent daemon"



}

################################################################################
if [ $# -eq 0 ]; then
    Help;
    exit 1
fi
while [ $# -gt 0 ]; do
  opt="$1"
  shift;
  current_arg="$1"
  case $current_arg in
    -[!-]* | --*)
      echo "WARNING: You may have left an argument blank. Double check your command."
      ;;
  esac
  case "$opt" in

        "-pv"|"--volume" ) createDir "$1"; echo PV="$(cd "$(dirname "$1")" || exit 1; pwd -P)"/"$(basename "$1")" >> "$ENV_FILE_TEMP"; shift;;
        "-h"|"--help"           )  Help; exit 1;;
        "-ai"|"--agentid" ) echo AI="$1" >> "$ENV_FILE_TEMP"; shift;;
        "-au"|"--autoupgrade" ) echo AU="$1" >> "$ENV_FILE_TEMP"; shift;;
        "-ap"|"--agentpackage" ) echo AP="$(cd "$(dirname "$1")" || exit 1; pwd -P)"/"$(basename "$1")" >> "$ENV_FILE_TEMP"; shift;;
        "-c"|"--config" ) configOverride=$(cd "$(dirname "$1")" || exit 1; pwd -P)/$(basename "$1"); shift;;
        "-nc"|"--newcontainer" ) newContainer=true;;
        "-i"|"--install"           ) install; exit 1;;
        "-up"|"--upgrade"           )  autoUpgrade; exit 1;;
        "-iu"|"--internalUpgrade"           )  upgrade; exit 1;;
        "-st"|"--stop"           ) stop; exit 1;;
        "-rs"|"--restart"           ) restart; exit 1;;
        "-u"|"--uninstall"           ) uninstall; exit 1;;
        "-s"|"--start"           ) start; exit 1;;
        "-sa"|"--status"           ) status; exit 1;;
        "-eau"|"--enableautoupgrade"  ) enableAutoUpgrade; exit 1;;
        "-dau"|"--disableautoupgrade"  ) disableAutoUpgrade; exit 1;;
        *                   ) echo "ERROR: agentManagement: Invalid option: \"$opt\"" >&2
                                                  exit 1;;
  esac
done
