#!/bin/sh
# Copyright (c) 2022 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
set -eu  # Exit on error
set -o pipefail  # Fail a pipe if any sub-command fails.

###########################################################
# Script constants
APPNAME="Management Agent"
LOGFILE=/var/log/mgmtagent_watchdog.log
BOOTSTRAP_HOME=/opt/oracle-mgmtagent-bootstrap
SCRIPTS=$BOOTSTRAP_HOME/scripts
PACKAGES=$BOOTSTRAP_HOME/packages
UPGRADE_STAGE=$BOOTSTRAP_HOME/upgrade
RUN_AGENT_AS_USER=mgmt_agent
CONFIG_FILE=/opt/oracle/mgmtagent_secret/input.rsp
MGMTAGENT_HOME=/opt/oracle/mgmt_agent
AUTOUPGRADE_BUNDLE=$MGMTAGENT_HOME/zip/oracle.mgmt_agent-??????.????.linux.zip
DOCKER_INSTALL_BUNDLE=$PACKAGES/oracle.mgmt_agent.zip


###########################################################
# Script imports
source "$SCRIPTS/common.sh"
source "$SCRIPTS/install_zip.sh"

echo $$ > /var/run/mgmtagent_watchdog.pid
trap "log 'Stopping container ...'; stop_agent; exit" SIGINT SIGTERM


###########################################################
# Check if agent upgrade is available
# Returns: 0 if upgrade exists otherwise 1
# Execute User Scope: user
function is_agent_upgrade_exist()
{
  local upgrader_file="$1"
  log "Checking upgrade bundle: [$upgrader_file]"
  if test -f "$upgrader_file"; then
    local upgrade_version=$(version_parse "$upgrader_file")
    log "Upgrade file version: [$upgrade_version]"
    local current_version=$($MGMTAGENT_HOME/agent_inst/bin/agentcore version)
    log "Current version: [$current_version]"

    if version_greater_than $upgrade_version $current_version; then
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
# Execute User Scope: user
function attempt_agent_upgrade()
{
  local upgrader_file=$(latest_upgrade_bundle "$AUTOUPGRADE_BUNDLE")
  local installer_file=$(latest_upgrade_bundle "$DOCKER_INSTALL_BUNDLE")

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
# Execute User Scope: user
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
# Check if agent run-as user exists
# Returns: 0 if user exists otherwise 1
# Execute User Scope: elevated
function is_agentrun_user_exist()
{
  if id "$RUN_AGENT_AS_USER" &> /dev/null; then
    log "$RUN_AGENT_AS_USER user exists"
    return 0
  else
    log "$RUN_AGENT_AS_USER user does not exist"
    return 1
  fi
}


###########################################################
# Create agent run-as user
# Returns: 0 if user was created otherwise 1
# Execute User Scope: elevated
function create_agentrun_user()
{
  local user_home_dir="/usr/share/$RUN_AGENT_AS_USER"
  local user_group_name="$RUN_AGENT_AS_USER"
  local user_comment="Disabled Oracle Polaris Agent"
  useradd -m -r -U -d "$user_home_dir" -s /bin/false -c "$user_comment" $RUN_AGENT_AS_USER
  local cmd_exit_code=$?
  if [ $cmd_exit_code -eq 0 ]; then
    log "$RUN_AGENT_AS_USER user created [status: $cmd_exit_code]"
    return 0
  else
    log "$RUN_AGENT_AS_USER user create failed [status: $cmd_exit_code]"
    return 1
  fi
}


###########################################################
# Check if agent is configured
# Returns: 0 if configured otherwise 1
# Execute User Scope: user
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
# Execute User Scope: elevated
function configure_agent()
{
  log "Configuring $APPNAME ..."
  if test -f "$CONFIG_FILE"; then
  	/opt/oracle/mgmt_agent/agent_inst/bin/setup.sh opts=$CONFIG_FILE
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
# Execute User Scope: mgmt_agent
function deploy_agent_initial_plugins()
{
  local ext_plugin_file="$MGMTAGENT_HOME/agent_inst/config/plugins.EXT"
  local meta_plugin_file="$MGMTAGENT_HOME/agent_inst/config/plugins.META"

  if [[ -f $ext_plugin_file || -f $meta_plugin_file ]]; then
    log "$APPNAME plugin deployment in progress ..."
    local current_version=$($MGMTAGENT_HOME/agent_inst/bin/agentcore version)
    log "Current version: [$current_version]"

    local java_exec=$($MGMTAGENT_HOME/agent_inst/bin/javaPath.sh)
    log "Java executable path: [$java_exec]"
    local java_cp="$MGMTAGENT_HOME/$current_version/jlib/agent-configure-*.jar"
    local java_class="oracle.polaris.configure.DeployPlugins"
    local jvm_args="-Djava.security.egd=file:///dev/./urandom"
    
    # plugin(s) must be deployed from agent_inst/bin
    pushd "$MGMTAGENT_HOME/agent_inst/bin"
    su -c "$java_exec $jvm_args -cp $java_cp $java_class" -s /bin/sh $RUN_AGENT_AS_USER &
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
# Execute User Scope: user
function is_agent_alive()
{
  local agent_pid_file=/opt/oracle/mgmt_agent/agent_inst/log/agent.pid
  if test -f "$agent_pid_file"; then
    local agent_pid=$(grep -Po "(?<=pid=)\d+" $agent_pid_file)
    if ps -p $agent_pid > /dev/null; then
      log "$APPNAME is running with PID: $agent_pid"
      return 0
    fi     
  fi

  # process not running (or old pid file found try restart)
  log "$APPNAME not running ..."
  return 1
}


###########################################################
# Start Management Agent and wait for startup to complete
# Returns: 0 if agent successfully started otherwise 1
# Execute User Scope: user
function start_agent()
{
  if is_agent_alive; then
      return 0
  fi

  log "Starting $APPNAME ..."
  su -c '/opt/oracle/mgmt_agent/agent_inst/bin/polaris_start.sh' -s /bin/sh $RUN_AGENT_AS_USER &

  local sleep_time=10
  local timeout=120
  local num_iterations=$(( timeout / sleep_time ))
  local counter=0

  while true; do
    if is_agent_alive; then
      deploy_agent_initial_plugins
      return 0
    else
      let counter=counter+1
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
# Execute User Scope: user
function stop_agent()
{
  log "Stopping $APPNAME ..."
  su -c '/opt/oracle/mgmt_agent/agent_inst/bin/polaris_stop.sh' -s /bin/sh $RUN_AGENT_AS_USER
}


###########################################################
# Main loop to keep the Management Agent process alive
# Args: $1 = agent pid
# Execute User Scope: elevated
function start_watchdog()
{
  local sleep_time=60
  while true; do
    if ! is_agent_alive; then
      attempt_agent_upgrade
    fi

  	start_agent || stop_agent
  	log "waiting $sleep_time seconds before next check"
    sleep $sleep_time
  done
}

###########################################################
# Main script execution
if ! is_agent_installed; then
  install_bundle=$(latest_upgrade_bundle "$DOCKER_INSTALL_BUNDLE")
  install_agent "$install_bundle"
fi

if ! is_agent_configured; then
  configure_agent
fi

if ! is_agentrun_user_exist; then
  create_agentrun_user
fi

start_watchdog
sleep 10
wait # for trap to work
