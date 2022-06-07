# Copyright (c) 2022 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

###########################################################
# Log messages with UTC date-time to log file and console
function log()
{
  if [ -n "$LOGFILE" ]; then
    printf '[%s] %s - %s\n' "`date -u`" "${0##*/}" "$@" >> "$LOGFILE" 2>&1
  fi
  printf '[%s] %s - %s\n' "`date -u`" "${0##*/}" "$@" 2>&1
}

###########################################################
# Trim leading and trailing whitespace characters of input
function trim() 
{
  local var=$1
  var="${var#"${var%%[![:space:]]*}"}"   # remove leading whitespace characters
  var="${var%"${var##*[![:space:]]}"}"   # remove trailing whitespace characters
  echo -n "$var"
}

###########################################################
# Expand the input by expanding quoted/escaped variables
function _expandVar()
{
  eval "echo -n \$$1 || true"
  return $?
}

###########################################################
# Is the first agent version greater than second
# Input: two agent version strings (format 210803.1717)
# Returns: 0 if first version gte second, otherwise 1
function version_greater_than()
{
  local date1=(${1%%.*}) time1=(${1##*.})
  local date2=(${2%%.*}) time2=(${2##*.})

  if [ "$date1" -gt "$date2" ]; then
    return 0
  fi

  if [ "$date1" -lt "$date2" ]; then
    return 1
  fi

  # dates are equal but times are not
  if [ "$time1" -gt "$time2" ]; then
    return 0
  fi

  if [ "$time1" -lt "$time2" ]; then
    return 1
  fi

  return 1
}

###########################################################
# Parses agent version from the upgrade zip filename
# Input: install zip filename (oracle.mgmt_agent.zip)
# Input: upgrade zip filename (oracle.mgmt_agent-210803.1717.linux.zip)
# Returns: agent version (210803.1717)
function version_parse()
{
  local var=$1
  if [ "${var}" == "${DOCKER_INSTALL_BUNDLE}" ]; then
    var=$(unzip -l "${var}" | grep -Po 'oracle.mgmt_agent-\d{6}.\d{4}.linux.zip')
  fi
  var=${var##*/}
  var=${var#${var%%[[:digit:]]*}}
  var=${var%%[[:alpha:]]*}
  var=${var%.};
  echo -n "$var"
}

###########################################################
# Executes the command from provided input parameters
# Input 1: command to execute
# Input 2: name of operation to execute
# Returns: 0 if execution is successful, 1 otherwise
function execute_cmd()
{
  local cmd="$1"
  local operation="$2"
  log "Executing ($operation): $cmd"
  eval $cmd
  
  local cmd_exit_code=$?
  if [ $cmd_exit_code -eq 0 ]; then
    log "$APPNAME $operation successful [status: $cmd_exit_code]"
    return 0
  else
    log "$APPNAME $operation failed [status: $cmd_exit_code]"
    return 1
  fi
}

###########################################################
# Find latest bundle, if any, matching the given pattern
# Input: oracle.mgmt_agent-??????.????.linux*.zip
# Returns: latest bundle (oracle.mgmt_agent-210803.1717.linux.zip)
function latest_upgrade_bundle()
{
  local -r glob_pattern=${1-}

  local latest_file=""
  local previous_version=""
  for upgrader_file in $glob_pattern ; do
    local current_version=$(version_parse "$upgrader_file")
    if [[ -z $latest_file ]] || version_greater_than $current_version $previous_version ; then
      latest_file=$upgrader_file
    fi
    previous_version=$current_version
  done

  [[ -n $latest_file ]] && echo -n "$latest_file"
  return 0
}
