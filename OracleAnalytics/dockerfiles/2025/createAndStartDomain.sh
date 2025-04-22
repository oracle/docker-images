#!/bin/bash -e
#
# Copyright (c) 2025 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Script to create a BI domain if it does not exist and then start the stack.

usage() {
cat << EOF

Usage: createAndStartDomain.sh
Start a Oracle Analytics Server domain, creating one if not yet available.

The following variables are mandatory when creating the domain (i.e. when starting the container first time):
  ORACLE_HOME - installation location (built into the image environment)
  DOMAINS_DIR - directory containing DOMAIN_HOME (built into the image environment)
  DOMAIN_NAME - Weblogic domain name (built into the image environment)
  ADMIN_USERNAME - WebLogic admin username for the new domain
  ADMIN_PASSWORD - Weblogic admin password
  DB_HOST - Host name for database into which new schemas will be created
  DB_PORT - Database listener port
  DB_SERVICE - Database instance service name
  DB_USERNAME - Database sysdba username
  DB_PASSWORD - Database sysdba password
  SCHEMA_PREFIX - Schema prefix for new schemas for the new domain
  SCHEMA_PASSWORD - Password for all new schemas

They can all be accepted as docker environment variables and/or Kubernetes secrets as environment variables.

The following files can also be used, overriding any environment already set.

For ADMIN_USERNAME/ADMIN_PASSWORD:
 - /run/secrets/admin.txt, or
 - /run/secrets/admin/username and /run/secrets/admin/password
For DB_USERNAME/DB_PASSWORD:
 - /run/secrets/db.txt, or
 - /run/secrets/db/username and /run/secrets/db/password
For SCHEMA_PASSWORD:
 - /run/secrets/schema.txt, or
 - /run/secrets/schema/password
For providing all keys:
 - /run/secrets/config.txt

Each *.txt file must contain lines of key=value pairs. This is intended docker secrets or docker run /v.
Each non-txt file must contain only the required value.  This is intended for Kubernetes secrets.

The following variable is optional:
  DB_WAIT_TIMEOUT - Wait for the given timeout (in seconds) for the database to be ready.  If not set, the database must already be ready.  If set, then DB_USERNAME/PASSWORD must be set (via any means) as this account is used to check the connection.  This setting is useful if the database is containerized and created at the same time as BI (e.g. via compose)

EOF
exit 0
}

_V=0
while getopts "hv" optname; do
  case "$optname" in
    "h")
      usage
      ;;
    "v")
      _V=1
      ;;
    *)
      usage
      ;;
  esac
done

function log () {
    if [[ $_V -eq 1 ]]; then
        echo "$@"
    fi
}

# Note that APPLICATIONS_DIR is always $ORACLE_HOME/user_projects/applications. Thus DOMAINS_DIR remains co-located.
# Mounting in $ORACLE_HOME/user_projects from a host o/s directory will work (if its permissions are correctly set).
# Mounting in $ORACLE_HOME/user_projects/domains/$DOMAIN_NAME will fail with ScriptExecutor configuration error.
# Separately mounting in $ORACLE_HOME/user_projects/domains/$DOMAIN_NAME/bidata (SDD) will fail with $DOMAIN_HOME in use configuration error.
DOMAIN_HOME=$DOMAINS_DIR/${DOMAIN_NAME:-bi}

# Use a touch file controlled by this script to ensure a container restart will know to start a successfully created domain.
# But don't allow start for a failed configuration (we could delete DOMAIN_HOME and retry instead?)
domainCheckFile=$DOMAIN_HOME/domainready.txt
if [ ! -f "$domainCheckFile" ] && [ -d "$DOMAIN_HOME" ]; then
  echo "An attempt was made to start a container with an incomplete DOMAIN_HOME"
  exit 2
fi

# Load parameters from various files, overriding any environment variables.
# Note we take care to not export these, so they are not visible to child processes
loadParametersFile() {
  file=$1/$2
  if [ -f "$file" ]; then
    if [ "txt" == "${file##*.}" ]; then
      parameters=$(xargs < "$file")
      log "Loaded from $file: $parameters"
      eval "$(sed -e "s/=\(.*\)/='\1'/g" < "$file")"
    else
      parameterKey=$(echo "$2" | tr /a-z/ /A-Z/ | tr / _)
      parameterValue=$(cat "$file")
      parameter="$parameterKey='$parameterValue'"
      log "Loaded from $file: $parameter"
      eval "$parameter"
    fi
  fi  
}

parameterFileDir=/run/secrets
parameterFiles=(config.txt admin.txt db.txt schema.txt admin/username admin/password db/username db/password schema/password)
for parameterFile in "${parameterFiles[@]}"; do
  loadParametersFile "$parameterFileDir" "$parameterFile"
done

# validate that all required parameters have been set somehow
validateMandatoryParameter() {
  key=$1
  if [ -z "${!key}" ]; then
    echo "$key"
  fi
}

# TODO only ORACLE_HOME/DOMAIN_NAME/DOMAINS_DIR is mandatory once domain is configured
mandatoryParameters=(ORACLE_HOME DOMAIN_NAME DOMAINS_DIR ADMIN_USERNAME ADMIN_PASSWORD DB_HOST DB_PORT DB_SERVICE DB_USERNAME DB_PASSWORD SCHEMA_PREFIX SCHEMA_PASSWORD BI_APP_LITE_PASSWORD)
missingMandatoryParameters=()
for mandatoryParameter in "${mandatoryParameters[@]}"; do
  missingParam=$(validateMandatoryParameter "$mandatoryParameter")

  if [[ ${missingParam} ]]; then
    missingMandatoryParameters+=("${missingParam}")
  fi
done

if (( ${#missingMandatoryParameters[@]} != 0 )); then
  missingParametersJoin=$(IFS="," ; echo "${missingMandatoryParameters[*]}")
  echo "The following mandatory parameters are not set: $missingParametersJoin"
  exit 1
fi

for parameter in "${mandatoryParameters[@]}"; do
  log "Parameter: $parameter=${!parameter}"
done

# If a wait timeout is set, block until the DB is available or the timeout is reached.
# This is useful when starting DB+BI via docker compose.
DB_WAIT_TIMEOUT=${DB_WAIT_TIMEOUT:-0}
if (( DB_WAIT_TIMEOUT > 0 )); then
 if [ -z "$DB_USERNAME" ] || [ -z "$DB_PASSWORD" ]; then
   echo "DB_USERNAME and DB_PASSWORD must be set if DB_WAIT_TIMEOUT is non-zero"
   exit 3
 fi
 set +e
 echo "$DB_PASSWORD" | timeout "$DB_WAIT_TIMEOUT" /u01/wait_for_db.sh "$ORACLE_HOME" "$DB_USERNAME" "$DB_HOST" "$DB_PORT" "$DB_SERVICE"
 exit_code="$?"
 if [ ! "${exit_code}" -eq 0 ]; then
    echo "Reached timeout waiting for DB to start - exiting"
    exit 1
 fi
 set -e
fi

# Create Domain only if 1st execution
if [ ! -f "$domainCheckFile" ]; then
  masterResponseFile=$ORACLE_HOME/bi/modules/oracle.bi.configassistant/response.txt

  tempDir=$(mktemp -dt "create_domain_XXXXXXXXXX")
  trap 'rm -rf -- "$tempDir"; kill -TERM $PID' INT TERM

  responseFile=$tempDir/response.txt
  cp "$masterResponseFile" "$responseFile"

  replacements="  -e \"s|@@DOMAIN_TYPE@@|DOMAIN_TYPE_EXPANDED|g\""
  replacements+=" -e \"s|@@CONFIGURE_ESSBASE@@|true|g\""
  replacements+=" -e \"s|@@CONFIGURE_BIEE@@|true|g\""
  replacements+=" -e \"s|@@CONFIGURE_BIP@@|true|g\""
  replacements+=" -e \"s|@@DOMAIN_NAME@@|$DOMAIN_NAME|g\""
  replacements+=" -e \"s|@@DOMAINS_DIR@@|$DOMAINS_DIR|g\""
  replacements+=" -e \"s|@@ADMIN_USER_NAME@@|$ADMIN_USERNAME|g\""
  replacements+=" -e \"s|@@ADMIN_PASSWORD@@|$ADMIN_PASSWORD|g\""
  replacements+=" -e \"s|@@SCHEMA_TYPE@@|SCHEMA_TYPE_NEW|g\""
  replacements+=" -e \"s|@@DB_TYPE@@|ORACLE|g\""
  replacements+=" -e \"s|@@DB_CONNECT_STRING@@|$DB_HOST:$DB_PORT:$DB_SERVICE|g\""
  replacements+=" -e \"s|@@DB_ADMIN_USERNAME@@|$DB_USERNAME|g\""
  replacements+=" -e \"s|@@DB_PASSWORD@@|$DB_PASSWORD|g\""
  replacements+=" -e \"s|@@PREFIX@@|$SCHEMA_PREFIX|g\""
  replacements+=" -e \"s|@@NEW_DB_SCHEMA_PASSWORD@@|$SCHEMA_PASSWORD|g\""
  replacements+=" -e \"s|@@NEW_DB_SCHEMA_PASSWORD@@|$SCHEMA_PASSWORD|g\""
  replacements+=" -e \"s|@@APPLICATION_TYPE@@|APPLICATION_TYPE_EMPTY|g\""
  replacements+=" -e \"s|@@AUTO_DROP_SCHEMAS@@|false|g\""
  replacements+=" -e \"s|@@DEFAULT_SI_KEY@@|ssi|g\""
  replacements+=" -e \"s|@@PORT_RANGE_START@@|9500|g\""
  replacements+=" -e \"s|@@PORT_RANGE_END@@|9999|g\""
  replacements+=" -e \"s|@@ENABLE_SSL@@|false|g\""
  replacements+=" -e \"s|@@DB_ROLE@@|SYSDBA|g\""
  replacements+=" -e \"s|@@APP_PASSWORD@@|$BI_APP_LITE_PASSWORD|g\""

  eval sed -i "$replacements" "$responseFile"

  "$ORACLE_HOME"/bi/bin/config.sh -ignoreSysPrereqs -silent -responseFile "$responseFile" &
  PID=$!
  wait $PID
  rm -f "$responseFile"
  trap - INT TERM

  echo "Do not delete this file - it tells the container createAndStartDomain.sh script that the domain is ready to be started" > "$domainCheckFile"
else
  "${DOMAIN_HOME}"/bitools/bin/start.sh
fi

trap '${DOMAIN_HOME}/bitools/bin/stop.sh; kill -TERM $PID' INT TERM
tail -f "${DOMAIN_HOME}"/servers/AdminServer/logs/"${DOMAIN_NAME}".log &
PID=$!
wait $PID
