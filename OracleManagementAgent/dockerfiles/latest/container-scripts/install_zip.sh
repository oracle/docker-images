# Copyright (c) 2022 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

###########################################################
# Unpack Management Agent install ZIP in non-service mode
# Returns: 0 if unpack successful otherwise error code
# Execute User Scope: elevated
function _unpack_install_bundle()
{
  local installer_file="$1"
  if [[ ! -f "$installer_file" ]] ; then
    log "Install file '$installer_file' not found"
    return 1
  fi

  log "Unpacking installer [$installer_file] ..."
  execute_cmd "unzip -o -qq $installer_file -d ${PACKAGES}/" "unpack"
  return $?
}

###########################################################
# Unpack Management Agent downloaded upgrade ZIP
# Returns: 0 if upgrade successful otherwise error code
# Execute User Scope: elevated
function _unpack_upgrade_bundle()
{
  local upgrader_file="$1"
  if [[ ! -f "$upgrader_file" ]] ; then
    log "Upgrade file '$upgrader_file' not found"
    return 1
  fi

  log "Upgrading $APPNAME ..."
  mkdir -p ${UPGRADE_STAGE}/zip

  # Get unpack jar
  log "Staging unpacker ..."
  execute_cmd "unzip -o -qq -j $upgrader_file */jlib/agent-unpack-*.jar \
    -d ${UPGRADE_STAGE}/zip/zip_extractor/" "unpack"

  # Get required scripts
  log "Staging upgrade scripts ..."
  execute_cmd "unzip -o -qq -j $upgrader_file agent_inst/bin/postinstallscript.sh \
    agent_inst/bin/preinstallscript.sh agent_inst/bin/installer.sh \
    agent_inst/bin/uninstaller.sh -d ${UPGRADE_STAGE}" "unpack"
  return $?
}

###########################################################
# Install Management Agent ZIP in non-service mode
# Returns: 0 if install successful otherwise error code
# Execute User Scope: elevated
function install_agent()
{
  export SYSTEM_MANAGER_OVERRIDE=true
  _unpack_install_bundle "$1"
  execute_cmd "/bin/bash ${PACKAGES}/installer.sh $CONFIG_FILE" "install"
  return $?
}

###########################################################
# Upgrade Management Agent using downloaded upgrade ZIP
# Returns: 0 if upgrade successful otherwise error code
# Execute User Scope: elevated
function upgrade_with_install_bundle()
{
  export SYSTEM_MANAGER_OVERRIDE=true
  _unpack_install_bundle "$1"
  execute_cmd "/bin/bash ${PACKAGES}/installer.sh -u" "upgrade"
  return $?
}

###########################################################
# Upgrade Management Agent using downloaded upgrade ZIP
# Returns: 0 if upgrade successful otherwise error code
# Execute User Scope: elevated
function upgrade_agent()
{
  export SYSTEM_MANAGER_OVERRIDE=true
  _unpack_upgrade_bundle "$1"
  execute_cmd "/bin/bash ${UPGRADE_STAGE}/installer.sh -u" "upgrade"
  return $?
}
