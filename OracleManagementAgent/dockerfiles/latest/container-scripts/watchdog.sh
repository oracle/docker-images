#!/bin/bash
# Copyright (c) 2023 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
set -eu  # Exit on error
set -o pipefail  # Fail a pipe if any sub-command fails.

###########################################################
# Script constants
APPNAME="Management Agent"
BASE_DIR=/opt/oracle
BOOTSTRAP_HOME="$BASE_DIR/bootstrap"
SCRIPTS=$BOOTSTRAP_HOME/scripts
PACKAGES=$BOOTSTRAP_HOME/packages
# shellcheck disable=SC2034
INSTALL_BASEDIR=$PACKAGES/mgmt_agent
# shellcheck disable=SC2034
UPGRADE_STAGE=$BOOTSTRAP_HOME/upgrade
CONFIG_FILE="$BASE_DIR/mgmtagent_secret/input.rsp"
MGMTAGENT_HOME="$BASE_DIR/mgmt_agent"
AUTOUPGRADE_BUNDLE="$MGMTAGENT_HOME/zip/oracle.mgmt_agent-??????.????.linux*.zip"
CONTAINER_INSTALL_BUNDLE=$PACKAGES/oracle.mgmt_agent.zip
LOGS_DIR="$BOOTSTRAP_HOME/logs"
# shellcheck disable=SC2034
LOGFILE="$LOGS_DIR/watchdog.log"
PIDFILE="$LOGS_DIR/watchdog.pid"


###########################################################
# Environment Constants
export DOCKER_USER_OVERRIDE=true
export DOCKER_BASE_DIR=$BASE_DIR


###########################################################
# Script imports
# shellcheck source=/dev/null
source "$SCRIPTS/common.sh"
# shellcheck source=/dev/null
source "$SCRIPTS/install_zip.sh"


###########################################################
# Initialize
echo $$ > "$PIDFILE"
trap "log 'Stopping container ...'; stop_agent; exit" SIGINT SIGTERM

###########################################################
# Check if agent upgrade is available
# Returns: 0 if upgrade exists otherwise 1
function is_agent_upgrade_exist()
{
  local upgrader_file="$1"
  log "Checking upgrade bundle: [$upgrader_file]"
  if test -f "$upgrader_file"; then
    local upgrade_version
    upgrade_version=$(version_parse "$upgrader_file")
    log "Upgrade file version: [$upgrade_version]"
    local current_version
    current_version=$(/bin/sh $MGMTAGENT_HOME/agent_inst/bin/agentcore version)
    log "Current version: [$current_version]"

    if version_greater_than "$upgrade_version" "$current_version"; then
      log "Upgrade required ..."
      return 0
    fi
  fi
  log "Upgrade not required ..."
  return 1
}

###########################################################
# Attempt to upgrade agent if upgrade bundle is available
# Returns: 0 if upgrade possible otherwise the error code
function attempt_agent_upgrade()
{
  local upgrader_file
  upgrader_file=$(latest_upgrade_bundle "$AUTOUPGRADE_BUNDLE")
  local installer_file
  installer_file=$(latest_upgrade_bundle "$CONTAINER_INSTALL_BUNDLE")

  if is_agent_upgrade_exist "$upgrader_file"; then
    upgrade_agent "$upgrader_file"
    return $?
  elif is_agent_upgrade_exist "$installer_file"; then
    upgrade_with_install_bundle "$installer_file"
    return $?
  fi
  return 0
}

###########################################################
# Check if agent is installed
# Returns: 0 if installed otherwise 1
function is_agent_installed()
{
  if test -f "$MGMTAGENT_HOME/installer-logs/installer.state.journal.SUCCESS"; then
    log "$APPNAME is installed"
    return 0
  else
    log "$APPNAME is not installed"
    return 1
  fi
}


###########################################################
# Check if agent is configured
# Returns: 0 if configured otherwise 1
function is_agent_configured()
{
  if test -f "$MGMTAGENT_HOME/agent_inst/config/configure.required"; then
    log "$APPNAME is not configured"
    return 1
  else
    log "$APPNAME is configured"
    return 0
  fi
}


###########################################################
# Configure Management Agent
# Returns: 0 if configure successful otherwise 1
function configure_agent()
{
  log "Configuring $APPNAME ..."
  if test -f "$CONFIG_FILE"; then
    execute_cmd "/bin/sh $MGMTAGENT_HOME/agent_inst/bin/setup.sh opts=$CONFIG_FILE" "configure agent"
  	local cmd_exit_code=$?
    if [ $cmd_exit_code -eq 0 ]; then
      log "$APPNAME configure successful [status: $cmd_exit_code]"
      :> $CONFIG_FILE
      return 0
    else
    	log "$APPNAME configure failed [status: $cmd_exit_code]"
  	  return 1
    fi
  else
  	log "Config file input.rsp not found"
  	return 1
  fi
}

###########################################################
# Check and deploy agent plugin(s) if required
# Returns: always returns 0, best effort only operation
function deploy_agent_initial_plugins()
{
  local ext_plugin_file="$MGMTAGENT_HOME/agent_inst/config/plugins.EXT"
  local meta_plugin_file="$MGMTAGENT_HOME/agent_inst/config/plugins.META"

  if [[ -f $ext_plugin_file || -f $meta_plugin_file ]]; then
    log "$APPNAME plugin deployment in progress ..."
    local current_version
    current_version=$(/bin/sh $MGMTAGENT_HOME/agent_inst/bin/agentcore version)
    log "Current version: [$current_version]"

    local java_exec
    java_exec=$(/bin/sh $MGMTAGENT_HOME/agent_inst/bin/javaPath.sh)
    log "Java executable path: [$java_exec]"
    local java_cp="$MGMTAGENT_HOME/$current_version/jlib"
    local java_class="oracle.polaris.configure.DeployPlugins"
    local jvm_args="-Djava.security.egd=file:///dev/./urandom"
    
    # plugin(s) must be deployed from agent_inst/bin
    pushd "$MGMTAGENT_HOME/agent_inst/bin"
    $java_exec "$jvm_args" -cp "$java_cp/"agent-configure-*.jar "$java_class" &
    log "$APPNAME plugin deployment outcome [status: $?]"
    popd
    return 0
  else
    log "$APPNAME plugin deployment not required"
    return 0
  fi
}

###########################################################
# Check if agent PID is alive
# Returns: 0 if alive otherwise 1
function is_agent_alive()
{
  local agent_pid_file="$MGMTAGENT_HOME/agent_inst/log/agent.pid"
  if test -f "$agent_pid_file"; then
    local agent_pid
    agent_pid=$(grep -Po "(?<=pid=)\d+" $agent_pid_file)
    if ps -p "$agent_pid" > /dev/null; then
      log "$APPNAME is running with PID: $agent_pid"
      return 0
    fi
  fi

  # process not running (or old pid file found try restart)
  log "$APPNAME not running ..."
  return 1
}

###########################################################
# Upsert properties with its overriding configMap
function agent_prop_upsert()
{
  log "invoking agent property upsert"
  # while upgrading from previous binary, the script will not be available
  # before the upgrade completes
  if [ ! -f $MGMTAGENT_HOME/agent_inst/bin/agent_prop_upsert.sh ]; then
    log "skipping property upsert"
  else
    # if the agent is alive then stop it first and then do the property update
    if is_agent_alive; then
	  stop_agent
    fi

    # upsert emd.properties
    prop_file=$MGMTAGENT_HOME/agent_inst/config/emd.properties
    config_map=$BASE_DIR/mgmtagent_agent_config/emd.properties
    eval "/bin/sh $MGMTAGENT_HOME/agent_inst/bin/agent_prop_upsert.sh $prop_file $config_map 'Modifiable Properties'"
  fi
}

###########################################################
# cleans up mgmt_agent dir if a new cleanup id is provided
function cleanup_agent_dir()
{
	log "initiating mgmt_agent dir cleanup"
	
	if [ -v POD_CLEANUP_ID ]; then
		# create the cleanup dir to maintain the marker files
		cleanup_id_dir="$BASE_DIR/cleanup_ids"
		mkdir -p $cleanup_id_dir
		
	    cleanup_id_file="$cleanup_id_dir/$POD_CLEANUP_ID.txt"
	    
	    if [ ! -f "$cleanup_id_file" ]; then
		    log "$cleanup_id_file not found"
		    rm -rf $MGMTAGENT_HOME
		    echo "cleanup successfully done" > "$cleanup_id_file"
		    log "cleanup completed"
		  else
		  	log "$cleanup_id_file found. skipping cleanup"
		fi
	    
	else
	    log "cleanup id not set. skipping cleanup"
	fi
}

###########################################################
# Start Management Agent and wait for startup to complete
# Returns: 0 if agent successfully started otherwise 1
function start_agent()
{
  if is_agent_alive; then
      return 0
  fi

  if [ -e "${SCRIPTS}/init-agent.sh" ]; then
    execute_cmd "/bin/sh ${SCRIPTS}/init-agent.sh" "initialize agent"
  fi

  log "Starting $APPNAME ..."
  discover_userinfo
  load_agent_java_options /opt/oracle/mgmt_agent/agent_inst/config/java.options
  execute_cmd "/bin/sh $MGMTAGENT_HOME/agent_inst/bin/polaris_start.sh &" "start agent"

  local sleep_time=10
  local timeout=120
  local num_iterations=$(( timeout / sleep_time ))
  local counter=0

  while true; do
    if is_agent_alive; then
      deploy_agent_initial_plugins
      return 0
    else
      (( counter++ ))
      if [ "$counter" -gt "$num_iterations" ]; then
        # waited long enough for agent to startup
        log "$APPNAME failed to start after waiting $timeout seconds"
        return 1
      fi
      # stay in the loop and wait until timeout
      log "waiting for $APPNAME to start, count # ($counter)"
      sleep $sleep_time
    fi
  done
}


###########################################################
# Stop Management Agent
function stop_agent()
{
  log "Stopping $APPNAME ..."
  execute_cmd "/bin/sh $MGMTAGENT_HOME/agent_inst/bin/polaris_stop.sh" "stop agent"
}


###########################################################
# Main loop to keep the Management Agent process alive
# Args: $1 = agent pid
function start_watchdog()
{
  local sleep_time=60
  while true; do
    if ! is_agent_alive; then
      attempt_agent_upgrade
      # previous binary will not consist the agent_prop_upsert.sh,
      # so the upgrade needs to happen first
      agent_prop_upsert
    fi

    start_agent || stop_agent
    log "waiting $sleep_time seconds before next check"
    sleep $sleep_time
  done
}

###########################################################
# Main script execution
cleanup_agent_dir

if ! is_agent_installed; then
  if [ ! -f "$CONFIG_FILE" ]; then
    log "$APPNAME install key (input.rsp) value [$CONFIG_FILE] is invalid or does not exist"
    exit 1
  fi

  install_bundle=$(latest_upgrade_bundle "$CONTAINER_INSTALL_BUNDLE")
  install_agent "$install_bundle"
fi

if ! is_agent_configured; then
  configure_agent
fi

# for fresh install
agent_prop_upsert

start_watchdog
sleep 10
wait # for trap to work